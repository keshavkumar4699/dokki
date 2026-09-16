package dev.dokki.platform_android.crypto

import dev.dokki.platform_android.keystore.KeySession
import java.io.File
import java.io.FileOutputStream
import java.io.OutputStream
import java.nio.ByteBuffer
import java.security.MessageDigest

/**
 * Envelope v1 (ARCHITECTURE.md §7.2), byte-for-byte the format
 * `vault_crypto`'s `EnvelopeCipher` writes and reads:
 *
 * ```
 * magic "PVLT1" | ver 0x01 | alg 0x01 | flags | epoch u32 BE | purpose |
 * wrapped_dek_len u16 BE | wrapped_dek | stream_salt[16] | header_tag[16]
 * body: chunks of AES-GCM(stream_key, nonce, aad, 256 KiB plaintext)
 *   nonce = salt[0..7] || counter u32 BE || final
 *   aad   = header_tag || counter u32 BE || final
 * ```
 * The native image pipeline reads and writes sealed files directly so
 * that no full-resolution plaintext ever crosses into Dart (§8.4).
 */
object EnvelopeFormat {
    val MAGIC: ByteArray = "PVLT1".toByteArray(Charsets.US_ASCII)
    const val VERSION = 1
    const val ALG_ID = 1
    const val CHUNK_SIZE = 256 * 1024
    const val TAG_SIZE = 16
    const val SALT_SIZE = 16
    const val FIXED_HEAD = 15 // magic(5) ver alg flags epoch(4) purpose wrappedLen(2)

    fun chunkNonce(salt: ByteArray, counter: Int, final: Int): ByteArray {
        val nonce = ByteArray(12)
        System.arraycopy(salt, 0, nonce, 0, 7)
        ByteBuffer.wrap(nonce, 7, 4).putInt(counter)
        nonce[11] = final.toByte()
        return nonce
    }

    fun chunkAad(headerTag: ByteArray, counter: Int, final: Int): ByteArray {
        val aad = ByteArray(21)
        System.arraycopy(headerTag, 0, aad, 0, 16)
        ByteBuffer.wrap(aad, 16, 4).putInt(counter)
        aad[20] = final.toByte()
        return aad
    }
}

/** Structural violation: not an envelope, wrong version, truncated, reordered. */
class EnvelopeFormatException(message: String) : Exception(message)

/** Purpose byte in the header differs from what the caller expected. */
class EnvelopePurposeMismatch(val expected: Int, val actual: Int) :
    Exception("envelope purpose $actual, expected $expected")

class EnvelopeHeader(
    val keyEpoch: Int,
    val purpose: Int,
    val compressed: Boolean,
    val wrappedDek: ByteArray,
    val streamSalt: ByteArray,
    val headerTag: ByteArray,
) {
    /** Serialised header EXCLUDING the tag (the tag's AAD). */
    fun bytesWithoutTag(): ByteArray {
        val out = ByteBuffer.allocate(EnvelopeFormat.FIXED_HEAD + wrappedDek.size + EnvelopeFormat.SALT_SIZE)
        out.put(EnvelopeFormat.MAGIC)
        out.put(EnvelopeFormat.VERSION.toByte())
        out.put(EnvelopeFormat.ALG_ID.toByte())
        out.put(if (compressed) 1 else 0)
        out.putInt(keyEpoch)
        out.put(purpose.toByte())
        out.putShort(wrappedDek.size.toShort())
        out.put(wrappedDek)
        out.put(streamSalt)
        return out.array()
    }

    fun toBytes(): ByteArray = bytesWithoutTag() + headerTag

    val encodedLength: Int
        get() = EnvelopeFormat.FIXED_HEAD + wrappedDek.size + EnvelopeFormat.SALT_SIZE + EnvelopeFormat.TAG_SIZE

    companion object {
        /** Parses a header from the front of [bytes]; does NOT verify the tag. */
        fun parse(bytes: ByteArray): EnvelopeHeader {
            if (bytes.size < EnvelopeFormat.FIXED_HEAD) throw EnvelopeFormatException("too short for a header")
            for (i in EnvelopeFormat.MAGIC.indices) {
                if (bytes[i] != EnvelopeFormat.MAGIC[i]) throw EnvelopeFormatException("bad magic")
            }
            if (bytes[5].toInt() != EnvelopeFormat.VERSION) throw EnvelopeFormatException("unsupported version")
            if (bytes[6].toInt() != EnvelopeFormat.ALG_ID) throw EnvelopeFormatException("unsupported alg_id")
            val flags = bytes[7].toInt()
            val buf = ByteBuffer.wrap(bytes)
            val epoch = buf.getInt(8)
            val purpose = bytes[12].toInt() and 0xFF
            val wrappedLen = buf.getShort(13).toInt() and 0xFFFF
            val saltStart = EnvelopeFormat.FIXED_HEAD + wrappedLen
            if (bytes.size < saltStart + EnvelopeFormat.SALT_SIZE + EnvelopeFormat.TAG_SIZE) {
                throw EnvelopeFormatException("truncated inside header")
            }
            return EnvelopeHeader(
                keyEpoch = epoch,
                purpose = purpose,
                compressed = (flags and 1) != 0,
                wrappedDek = bytes.copyOfRange(EnvelopeFormat.FIXED_HEAD, saltStart),
                streamSalt = bytes.copyOfRange(saltStart, saltStart + EnvelopeFormat.SALT_SIZE),
                headerTag = bytes.copyOfRange(saltStart + EnvelopeFormat.SALT_SIZE, saltStart + 32),
            )
        }
    }
}

/** What a seal produced, for the `blobs` row Dart writes (§7.3 step 5). */
class SealedFileInfo(
    val keyEpoch: Int,
    val wrappedDek: ByteArray,
    val plaintextSize: Long,
    val ciphertextSize: Long,
    val plaintextSha256: String,
    val ciphertextSha256: String,
)

class EnvelopeReader(private val session: KeySession) {
    /**
     * Opens a sealed file fully into memory, verifying every tag, the
     * header, chunk order and the final flag. Plaintext stays native;
     * callers zero it when done. Throws [TagVerificationFailed] on any
     * integrity violation and [EnvelopeFormatException] on structure.
     */
    fun readAll(file: File, expectedPurpose: Int): ByteArray = readAll(file.readBytes(), expectedPurpose)

    fun readAll(sealed: ByteArray, expectedPurpose: Int): ByteArray {
        val header = EnvelopeHeader.parse(sealed)
        if (header.purpose != expectedPurpose) throw EnvelopePurposeMismatch(expectedPurpose, header.purpose)
        val keyId = session.bindWrapped(header.wrappedDek, header.keyEpoch, header.purpose)
        try {
            val headerLength = header.encodedLength
            session.verifyHeader(
                keyId,
                header.streamSalt,
                sealed.copyOfRange(0, headerLength - EnvelopeFormat.TAG_SIZE),
                header.headerTag,
            )
            val out = java.io.ByteArrayOutputStream(maxOf(0, sealed.size - headerLength))
            var offset = headerLength
            var counter = 0
            val fullChunk = EnvelopeFormat.CHUNK_SIZE + EnvelopeFormat.TAG_SIZE
            while (true) {
                val remaining = sealed.size - offset
                if (remaining <= 0) throw EnvelopeFormatException("truncated: missing final chunk")
                val final = if (remaining < fullChunk) 1 else 0
                val take = if (final == 1) remaining else fullChunk
                val plaintext = session.decryptChunk(
                    keyId,
                    header.streamSalt,
                    EnvelopeFormat.chunkNonce(header.streamSalt, counter, final),
                    EnvelopeFormat.chunkAad(header.headerTag, counter, final),
                    sealed.copyOfRange(offset, offset + take),
                )
                if (final == 0 && plaintext.size != EnvelopeFormat.CHUNK_SIZE) {
                    throw EnvelopeFormatException("non-final chunk has invalid size")
                }
                out.write(plaintext)
                plaintext.fill(0)
                offset += take
                counter++
                if (final == 1) break
            }
            return out.toByteArray()
        } finally {
            session.release(keyId)
        }
    }

    /** Header only — dimensions of nothing, but the epoch and purpose. */
    fun header(file: File): EnvelopeHeader {
        val head = ByteArray(minOf(file.length(), 4096L).toInt())
        file.inputStream().use { it.read(head) }
        return EnvelopeHeader.parse(head)
    }
}

class EnvelopeWriter(private val session: KeySession) {
    /**
     * Seals [plaintext] to [file] under a fresh DEK wrapped for
     * `K_<purpose>(epoch)`. The caller owns atomicity (write to a `.part`
     * path, rename after). Hashes both sides so the blob row is exact.
     */
    fun sealTo(file: File, plaintext: ByteArray, epoch: Int, purpose: Int): SealedFileInfo {
        file.parentFile?.mkdirs()
        FileOutputStream(file).use { out ->
            return seal(out, plaintext, epoch, purpose)
        }
    }

    fun seal(out: OutputStream, plaintext: ByteArray, epoch: Int, purpose: Int): SealedFileInfo {
        val (wrapped, keyId) = session.generateAndBind(epoch, purpose)
        try {
            val salt = Primitives.randomBytes(EnvelopeFormat.SALT_SIZE)
            val untagged = EnvelopeHeader(epoch, purpose, false, wrapped, salt, ByteArray(16)).bytesWithoutTag()
            val tag = session.sealHeader(keyId, salt, untagged)
            val headerBytes = untagged + tag
            val ciphertextDigest = MessageDigest.getInstance("SHA-256")
            val plaintextDigest = MessageDigest.getInstance("SHA-256")
            plaintextDigest.update(plaintext)
            out.write(headerBytes)
            ciphertextDigest.update(headerBytes)
            var ciphertextSize = headerBytes.size.toLong()

            var offset = 0
            var counter = 0
            // Every full 256 KiB is a non-final chunk; whatever is left
            // (possibly nothing) is the explicit final chunk (§7.2).
            while (plaintext.size - offset >= EnvelopeFormat.CHUNK_SIZE) {
                val ct = session.encryptChunk(
                    keyId, salt,
                    EnvelopeFormat.chunkNonce(salt, counter, 0),
                    EnvelopeFormat.chunkAad(tag, counter, 0),
                    plaintext.copyOfRange(offset, offset + EnvelopeFormat.CHUNK_SIZE),
                )
                out.write(ct)
                ciphertextDigest.update(ct)
                ciphertextSize += ct.size
                offset += EnvelopeFormat.CHUNK_SIZE
                counter++
            }
            val last = session.encryptChunk(
                keyId, salt,
                EnvelopeFormat.chunkNonce(salt, counter, 1),
                EnvelopeFormat.chunkAad(tag, counter, 1),
                plaintext.copyOfRange(offset, plaintext.size),
            )
            out.write(last)
            ciphertextDigest.update(last)
            ciphertextSize += last.size
            out.flush()
            return SealedFileInfo(
                keyEpoch = epoch,
                wrappedDek = wrapped,
                plaintextSize = plaintext.size.toLong(),
                ciphertextSize = ciphertextSize,
                plaintextSha256 = plaintextDigest.digest().toHex(),
                ciphertextSha256 = ciphertextDigest.digest().toHex(),
            )
        } finally {
            session.release(keyId)
        }
    }
}

fun ByteArray.toHex(): String = joinToString("") { "%02x".format(it) }

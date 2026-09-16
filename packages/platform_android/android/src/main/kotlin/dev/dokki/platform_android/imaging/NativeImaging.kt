package dev.dokki.platform_android.imaging

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.Matrix
import android.media.ExifInterface
import dev.dokki.platform_android.crypto.EnvelopeReader
import dev.dokki.platform_android.crypto.EnvelopeWriter
import dev.dokki.platform_android.crypto.SealedFileInfo
import dev.dokki.platform_android.keystore.KeySession
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.OutputStream
import java.security.MessageDigest
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt
import kotlin.math.sqrt

/** The decoder could not make sense of the bytes. */
class UndecodableImageException : Exception("undecodable image")

/** The source exceeds the decode ceiling even at the coarsest subsampling. */
class DecodeTooLargeException(val width: Int, val height: Int, val limit: Long) :
    Exception("${width}x$height exceeds $limit px")

class DecodedImage(val bitmap: Bitmap, val mime: String, val sourceWidth: Int, val sourceHeight: Int)

/**
 * Phase 4 (§17): the native image pipeline. Sealed file → decrypt in
 * native memory → `BitmapFactory` at the smallest sufficient
 * `inSampleSize` → EXIF orientation baked → ops → encode → seal. No
 * full-resolution plaintext ever reaches Dart (§8.4, R2).
 */
class NativeImaging(session: KeySession) {
    private val reader = EnvelopeReader(session)
    private val writer = EnvelopeWriter(session)

    // ── Inspection ──────────────────────────────────────────────────────────

    class Info(val width: Int, val height: Int, val mime: String)

    fun inspect(file: File, purpose: Int): Info {
        val plaintext = reader.readAll(file, purpose)
        try {
            val opts = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeByteArray(plaintext, 0, plaintext.size, opts)
            if (opts.outWidth <= 0 || opts.outHeight <= 0) throw UndecodableImageException()
            return Info(opts.outWidth, opts.outHeight, opts.outMimeType ?: "application/octet-stream")
        } finally {
            plaintext.fill(0)
        }
    }

    // ── Decode ──────────────────────────────────────────────────────────────

    /**
     * Decodes at the coarsest power-of-two subsampling that still yields
     * at least [targetPixels] pixels (or the full image if it is smaller),
     * refusing anything that would exceed [maxPixels] even so.
     */
    fun decode(sealed: File, purpose: Int, targetPixels: Long, maxPixels: Long): DecodedImage {
        val plaintext = reader.readAll(sealed, purpose)
        try {
            return decodeBytes(plaintext, targetPixels, maxPixels)
        } finally {
            plaintext.fill(0)
        }
    }

    fun decodeBytes(plaintext: ByteArray, targetPixels: Long, maxPixels: Long): DecodedImage {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(plaintext, 0, plaintext.size, bounds)
        val w = bounds.outWidth
        val h = bounds.outHeight
        if (w <= 0 || h <= 0) throw UndecodableImageException()
        var sample = 1
        while ((w.toLong() / (sample * 2)) * (h.toLong() / (sample * 2)) >= targetPixels) sample *= 2
        val decodedPixels = (w.toLong() / sample) * (h.toLong() / sample)
        if (decodedPixels > maxPixels) throw DecodeTooLargeException(w, h, maxPixels)
        val opts = BitmapFactory.Options().apply {
            inSampleSize = sample
            inPreferredConfig = Bitmap.Config.ARGB_8888
            inMutable = false
        }
        val bitmap = BitmapFactory.decodeByteArray(plaintext, 0, plaintext.size, opts)
            ?: throw UndecodableImageException()
        val upright = bakeOrientation(bitmap, plaintext)
        return DecodedImage(upright, bounds.outMimeType ?: "image/jpeg", w, h)
    }

    /** Applies the EXIF orientation so every downstream coordinate is upright. */
    private fun bakeOrientation(bitmap: Bitmap, bytes: ByteArray): Bitmap {
        val orientation = try {
            ExifInterface(ByteArrayInputStream(bytes))
                .getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)
        } catch (e: Exception) {
            ExifInterface.ORIENTATION_NORMAL
        }
        val matrix = Matrix()
        when (orientation) {
            ExifInterface.ORIENTATION_ROTATE_90 -> matrix.postRotate(90f)
            ExifInterface.ORIENTATION_ROTATE_180 -> matrix.postRotate(180f)
            ExifInterface.ORIENTATION_ROTATE_270 -> matrix.postRotate(270f)
            ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> matrix.preScale(-1f, 1f)
            ExifInterface.ORIENTATION_FLIP_VERTICAL -> matrix.preScale(1f, -1f)
            ExifInterface.ORIENTATION_TRANSPOSE -> { matrix.postRotate(90f); matrix.preScale(-1f, 1f) }
            ExifInterface.ORIENTATION_TRANSVERSE -> { matrix.postRotate(270f); matrix.preScale(-1f, 1f) }
            else -> return bitmap
        }
        val rotated = Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
        if (rotated !== bitmap) bitmap.recycle()
        return rotated
    }

    // ── Process (ImageProcessor.apply / applyChain / preview) ──────────────

    class Processed(val width: Int, val height: Int, val mime: String, val sealed: SealedFileInfo)

    fun process(
        input: File,
        inputPurpose: Int,
        output: File,
        outputPurpose: Int,
        epoch: Int,
        opsJson: String,
        decodeTargetPixels: Long,
        maxDecodedPixels: Long,
        maxEdge: Int,
        preferredMime: String?,
        quality: Int,
    ): Processed {
        val decoded = decode(input, inputPurpose, decodeTargetPixels, maxDecodedPixels)
        var bitmap = decoded.bitmap
        try {
            for (op in ImageOps.parse(opsJson)) {
                bitmap = ImageOps.apply(bitmap, op)
            }
            if (maxEdge > 0) {
                val longest = max(bitmap.width, bitmap.height)
                if (longest > maxEdge) {
                    val scale = maxEdge.toDouble() / longest
                    bitmap = ImageOps.resize(
                        bitmap,
                        (bitmap.width * scale).roundToInt().coerceIn(1, maxEdge),
                        (bitmap.height * scale).roundToInt().coerceIn(1, maxEdge),
                        "stretch",
                        Color.WHITE,
                    )
                }
            }
            val mime = preferredMime ?: decoded.mime
            val encoded = encode(bitmap, mime, quality)
            try {
                val sealed = writer.sealTo(output, encoded, epoch, outputPurpose)
                return Processed(bitmap.width, bitmap.height, outputMime(mime), sealed)
            } finally {
                encoded.fill(0)
            }
        } finally {
            bitmap.recycle()
        }
    }

    // ── Encode ──────────────────────────────────────────────────────────────

    fun encode(bitmap: Bitmap, mime: String, quality: Int): ByteArray {
        val out = ByteArrayOutputStream()
        encodeTo(out, bitmap, mime, quality)
        return out.toByteArray()
    }

    fun encodeTo(out: OutputStream, bitmap: Bitmap, mime: String, quality: Int) {
        val ok = when (mime) {
            "image/png" -> bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
            else -> {
                val flat = ImageOps.flatten(bitmap, Color.WHITE)
                try {
                    flat.compress(Bitmap.CompressFormat.JPEG, quality.coerceIn(1, 100), out)
                } finally {
                    if (flat !== bitmap) flat.recycle()
                }
            }
        }
        if (!ok) throw UndecodableImageException()
    }

    fun outputMime(mime: String): String = if (mime == "image/png") "image/png" else "image/jpeg"

    // ── Export rasters (RasterEngine) ───────────────────────────────────────

    class Raster(val bitmap: Bitmap, val sourceWidth: Int, val sourceHeight: Int, val background: Int)

    fun prepareRaster(
        input: File,
        purpose: Int,
        width: Int?,
        height: Int?,
        fit: String,
        grayscale: Boolean,
        bw: Boolean,
        background: Int?,
        maxDecodedPixels: Long,
    ): Raster {
        // Decode no more than needed: the plan's target (if any) times a
        // small margin so resampling has real pixels to work from.
        val target = if (width != null && height != null) {
            width.toLong() * height.toLong() * 4
        } else if (width != null) {
            width.toLong() * width.toLong() * 4
        } else if (height != null) {
            height.toLong() * height.toLong() * 4
        } else {
            maxDecodedPixels
        }
        val decoded = decode(input, purpose, min(target, maxDecodedPixels), maxDecodedPixels)
        var bitmap = decoded.bitmap
        if (width != null || height != null) {
            bitmap = ImageOps.resize(bitmap, width, height, fit, background ?: Color.WHITE)
        }
        if (bw) {
            bitmap = ImageOps.filter(bitmap, "bw")
        } else if (grayscale) {
            bitmap = ImageOps.filter(bitmap, "grayscale")
        }
        return Raster(bitmap, decoded.sourceWidth, decoded.sourceHeight, background ?: Color.WHITE)
    }

    /** Encode-to-count: bytes the encoder would produce, without keeping them. */
    fun measure(raster: Raster, mime: String, quality: Int): Long {
        val counter = CountingOutputStream()
        encodeTo(counter, raster.bitmap, mime, quality)
        return counter.count
    }

    fun downscale(raster: Raster, factor: Double): Raster {
        val w = (raster.bitmap.width * factor).roundToInt().coerceIn(1, raster.bitmap.width)
        val h = (raster.bitmap.height * factor).roundToInt().coerceIn(1, raster.bitmap.height)
        val scaled = Bitmap.createScaledBitmap(raster.bitmap, w, h, true)
        return Raster(scaled, raster.sourceWidth, raster.sourceHeight, raster.background)
    }

    private class CountingOutputStream : OutputStream() {
        var count = 0L
        override fun write(b: Int) { count++ }
        override fun write(b: ByteArray, off: Int, len: Int) { count += len }
    }

    companion object {
        fun sha256Hex(bytes: ByteArray): String =
            MessageDigest.getInstance("SHA-256").digest(bytes).joinToString("") { "%02x".format(it) }

        /** Largest power-of-two subsampling that keeps ≥ [target] pixels. */
        fun sampleSizeFor(width: Int, height: Int, target: Long): Int {
            var sample = 1
            while ((width.toLong() / (sample * 2)) * (height.toLong() / (sample * 2)) >= target) sample *= 2
            return sample
        }

        fun fitFactor(currentPixels: Long, targetPixels: Long): Double =
            if (currentPixels <= targetPixels) 1.0 else sqrt(targetPixels.toDouble() / currentPixels)
    }
}

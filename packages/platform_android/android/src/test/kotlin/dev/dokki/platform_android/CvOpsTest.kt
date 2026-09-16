package dev.dokki.platform_android

import dev.dokki.platform_android.imaging.CvOps
import kotlin.math.abs
import kotlin.math.sqrt
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * JVM tests for the hand-written CV kernels (§13, Phase 8): homography,
 * perspective warp, bilateral denoise, and the document-quad detector.
 * All kernels work on plain pixel arrays — no Android types involved.
 */
class CvOpsTest {

    private fun argb(r: Int, g: Int, b: Int) =
        (0xFF shl 24) or (r shl 16) or (g shl 8) or b

    // ── Homography ─────────────────────────────────────────────────────────

    @Test
    fun `homography of an identity mapping is the identity`() {
        val pts = floatArrayOf(0f, 0f, 100f, 0f, 100f, 50f, 0f, 50f)
        val h = CvOps.homography(pts, pts)
        for (x in 0 until 100 step 17) {
            for (y in 0 until 50 step 11) {
                val dx = x + 0.5f
                val dy = y + 0.5f
                val denom = h[6] * dx + h[7] * dy + h[8]
                val sx = (h[0] * dx + h[1] * dy + h[2]) / denom
                val sy = (h[3] * dx + h[4] * dy + h[5]) / denom
                assertEquals(dx, sx, 0.01f, "x=$x y=$y")
                assertEquals(dy, sy, 0.01f, "x=$x y=$y")
            }
        }
    }

    @Test
    fun `homography maps a rotated square onto the frame`() {
        // A diamond (rotated square) → the full 100×100 frame.
        val src = floatArrayOf(50f, 0f, 100f, 50f, 50f, 100f, 0f, 50f)
        val dst = floatArrayOf(0f, 0f, 100f, 0f, 100f, 100f, 0f, 100f)
        val h = CvOps.homography(dst, src)
        // Frame centre maps to the diamond centre.
        val cx = 50f
        val cy = 50f
        val denom = h[6] * cx + h[7] * cy + h[8]
        val sx = (h[0] * cx + h[1] * cy + h[2]) / denom
        val sy = (h[3] * cx + h[4] * cy + h[5]) / denom
        assertEquals(50f, sx, 1f)
        assertEquals(50f, sy, 1f)
    }

    // ── Warp ───────────────────────────────────────────────────────────────

    @Test
    fun `warp of a white square inside a dark frame fills the output`() {
        // 20×20 image: a white 10×10 square at (5,5); warp it to 10×10.
        val w = 20
        val h = 20
        val img = IntArray(w * h) { i ->
            val x = i % w
            val y = i / w
            if (x in 5..14 && y in 5..14) argb(255, 255, 255) else argb(0, 0, 0)
        }
        val src = floatArrayOf(5f, 5f, 15f, 5f, 15f, 15f, 5f, 15f)
        val dst = floatArrayOf(0f, 0f, 10f, 0f, 10f, 10f, 0f, 10f)
        val hInv = CvOps.homography(dst, src)
        val out = CvOps.warpPerspective(img, w, h, hInv, 10, 10)
        // Interior pixels are white (edges may blend into the border).
        for (y in 2 until 8) {
            for (x in 2 until 8) {
                val c = out[y * 10 + x]
                assertEquals(0xFF, (c ushr 16) and 0xFF, "red at $x,$y")
            }
        }
    }

    // ── Denoise ────────────────────────────────────────────────────────────

    @Test
    fun `denoise is a no-op on a flat image`() {
        val img = IntArray(64) { argb(120, 80, 40) }
        val out = CvOps.denoise(img, 8, 8, 2)
        for (i in img.indices) {
            assertEquals(img[i], out[i], "pixel $i")
        }
    }

    @Test
    fun `denoise smooths grain noise and preserves a step edge`() {
        // Grain: a 100-field with ±25 deterministic noise. Bilateral
        // filtering pulls every pixel back toward the field mean.
        var seed = 7
        val noisy = IntArray(100) {
            seed = (seed * 1103515245 + 12345) and 0x7FFFFFFF
            val delta = (seed % 51) - 25
            argb(100 + delta, 100 + delta, 100 + delta)
        }
        fun variance(pixels: IntArray): Double {
            val mean = pixels.map { (it ushr 16) and 0xFF }.average()
            return pixels.map {
                val d = ((it ushr 16) and 0xFF) - mean
                d * d
            }.average()
        }
        val smoothed = CvOps.denoise(noisy, 10, 10, 1)
        assertTrue(
            variance(smoothed) < variance(noisy) * 0.8,
            "grain variance shrinks (was ${variance(noisy)}, now ${variance(smoothed)})",
        )

        // A step edge must stay sharp: bilateral filtering is edge-aware.
        // Columns 0–4 are dark, 5–9 bright; sample away from the boundary.
        val edge = IntArray(100) { i -> if (i % 10 < 5) argb(40, 40, 40) else argb(220, 220, 220) }
        val edged = CvOps.denoise(edge, 10, 10, 1)
        val darkSide = (edged[42] ushr 16) and 0xFF
        val brightSide = (edged[47] ushr 16) and 0xFF
        assertTrue(darkSide < 100, "dark side stays dark (got $darkSide)")
        assertTrue(brightSide > 160, "bright side stays bright (got $brightSide)")
    }

    // ── Detector ───────────────────────────────────────────────────────────

    @Test
    fun `detector finds a white document on a dark background`() {
        val w = 100
        val h = 80
        val img = IntArray(w * h) { argb(20, 20, 25) }
        // Document: white quad from (15,10) to (85,70), slightly skewed.
        val quad = floatArrayOf(15f, 10f, 85f, 12f, 83f, 70f, 17f, 68f)
        val dst = floatArrayOf(15f, 10f, 85f, 12f, 83f, 70f, 17f, 68f)
        val hInv = CvOps.homography(dst, quad)
        for (y in 10 until 70) {
            for (x in 15 until 85) {
                img[y * w + x] = argb(230, 230, 225)
            }
        }
        val found = CvOps.detectDocumentQuad(img, w, h)
        assertNotNull(found, "a clean document must be found")
        // Every detected corner is within ~10 px of the true corner.
        for (i in 0 until 4) {
            val dx = found.corners[i * 2] - quad[i * 2]
            val dy = found.corners[i * 2 + 1] - quad[i * 2 + 1]
            val dist = sqrt(dx * dx + dy * dy)
            assertTrue(dist < 10f, "corner $i off by $dist px")
        }
    }

    @Test
    fun `detector rejects a full-frame blob and pure noise`() {
        val w = 64
        val h = 64
        val full = IntArray(w * h) { argb(240, 240, 240) }
        assertNull(CvOps.detectDocumentQuad(full, w, h), "no doc in a full frame")
        var seed = 42
        val noise = IntArray(w * h) {
            seed = (seed * 1103515245 + 12345) and 0x7FFFFFFF
            if (seed % 2 == 0) argb(10, 10, 10) else argb(245, 245, 245)
        }
        // Noise either finds nothing or a blob far outside a document's shape.
        val found = CvOps.detectDocumentQuad(noise, w, h, minCoverage = 0.30f)
        assertNull(found, "speckle noise is not a document")
    }

    // ── Output sizing ──────────────────────────────────────────────────────

    @Test
    fun `warp output follows the quad edge lengths`() {
        val quad = floatArrayOf(0f, 0f, 40f, 0f, 40f, 30f, 0f, 30f)
        val (w, h) = CvOps.warpOutputSize(quad)
        assertEquals(40, w)
        assertEquals(30, h)
    }
}

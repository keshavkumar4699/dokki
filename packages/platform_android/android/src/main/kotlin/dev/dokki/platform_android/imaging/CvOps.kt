package dev.dokki.platform_android.imaging

import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt
import kotlin.math.sqrt

/**
 * Hand-written CV kernels for Phase 8 (§15.5 "hand-written kernels for
 * just the four operations we need"): homography solve + perspective warp,
 * bilateral denoise, and a document-quad detector.
 *
 * Everything here works on plain pixel arrays, NOT `android.graphics`
 * types, so the kernels are unit-testable on the JVM with zero Android
 * (§1.2). The `android.graphics.Bitmap` adapters live in `ImageOps`.
 */
object CvOps {

    // ── Homography (direct linear transform, 4 point pairs) ────────────────

    /**
     * Solves the 3x3 homography mapping src→dst for exactly 4 point pairs
     * (Gaussian elimination with partial pivoting). Returns row-major
     * [h11, h12, h13, h21, h22, h23, h31, h32, 1].
     */
    fun homography(src: FloatArray, dst: FloatArray): FloatArray {
        require(src.size == 8 && dst.size == 8) { "need exactly 4 point pairs" }
        // A h = b, one 2-row block per point pair.
        val a = Array(8) { DoubleArray(9) }
        for (i in 0 until 4) {
            val x = src[i * 2].toDouble()
            val y = src[i * 2 + 1].toDouble()
            val u = dst[i * 2].toDouble()
            val v = dst[i * 2 + 1].toDouble()
            a[i * 2] = doubleArrayOf(x, y, 1.0, 0.0, 0.0, 0.0, -u * x, -u * y, u)
            a[i * 2 + 1] = doubleArrayOf(0.0, 0.0, 0.0, x, y, 1.0, -v * x, -v * y, v)
        }
        // Solve the 8x8 system (column 8 is the RHS).
        for (col in 0 until 8) {
            var pivot = col
            for (row in col + 1 until 8) {
                if (abs(a[row][col]) > abs(a[pivot][col])) pivot = row
            }
            val tmp = a[col]; a[col] = a[pivot]; a[pivot] = tmp
            val div = a[col][col]
            check(abs(div) > 1e-12) { "degenerate point configuration" }
            for (j in col until 9) a[col][j] /= div
            for (row in 0 until 8) {
                if (row == col) continue
                val f = a[row][col]
                for (j in col until 9) a[row][j] -= f * a[col][j]
            }
        }
        return floatArrayOf(
            a[0][8].toFloat(), a[1][8].toFloat(), a[2][8].toFloat(),
            a[3][8].toFloat(), a[4][8].toFloat(), a[5][8].toFloat(),
            a[6][8].toFloat(), a[7][8].toFloat(), 1f,
        )
    }

    /**
     * Warps [src] (w×h ARGB) into an outW×outH image by INVERSE-mapping
     * every output pixel through [hInv] (dst→src homography) and sampling
     * bilinearly. Out-of-frame samples are [background].
     */
    fun warpPerspective(
        src: IntArray, w: Int, h: Int,
        hInv: FloatArray,
        outW: Int, outH: Int,
        background: Int = -0x1, // opaque white
    ): IntArray {
        val out = IntArray(outW * outH)
        for (y in 0 until outH) {
            for (x in 0 until outW) {
                val dx = x + 0.5f
                val dy = y + 0.5f
                val denom = hInv[6] * dx + hInv[7] * dy + hInv[8]
                val sx = (hInv[0] * dx + hInv[1] * dy + hInv[2]) / denom
                val sy = (hInv[3] * dx + hInv[4] * dy + hInv[5]) / denom
                out[y * outW + x] = bilinear(src, w, h, sx - 0.5f, sy - 0.5f, background)
            }
        }
        return out
    }

    private fun bilinear(src: IntArray, w: Int, h: Int, fx: Float, fy: Float, background: Int): Int {
        val x0 = fx.toInt()
        val y0 = fy.toInt()
        if (x0 < -1 || y0 < -1 || x0 >= w || y0 >= h) return background
        val tx = fx - x0
        val ty = fy - y0
        fun px(x: Int, y: Int): Int =
            if (x in 0 until w && y in 0 until h) src[y * w + x] else background
        val c00 = px(x0, y0)
        val c10 = px(x0 + 1, y0)
        val c01 = px(x0, y0 + 1)
        val c11 = px(x0 + 1, y0 + 1)
        fun channel(shift: Int): Int {
            val v00 = (c00 ushr shift) and 0xFF
            val v10 = (c10 ushr shift) and 0xFF
            val v01 = (c01 ushr shift) and 0xFF
            val v11 = (c11 ushr shift) and 0xFF
            val top = v00 + (v10 - v00) * tx
            val bottom = v01 + (v11 - v01) * tx
            return (top + (bottom - top) * ty).roundToInt().coerceIn(0, 255)
        }
        return (channel(24) shl 24) or (channel(16) shl 16) or (channel(8) shl 8) or channel(0)
    }

    // ── Denoise (bilateral filter) ──────────────────────────────────────────

    /**
     * Bilateral filter (deterministic): spatial Gaussian × range Gaussian
     * over a small window. [radius] is 1 (light), 2 (medium) or 3 (strong)
     * — matching `DenoiseStrength`.
     */
    fun denoise(src: IntArray, w: Int, h: Int, radius: Int): IntArray {
        if (radius <= 0) return src
        val sigmaS = radius.toDouble()
        val sigmaR = 0.12 // normalised channel distance
        val spatial = DoubleArray(2 * radius + 1) { d ->
            Math.exp(-(d * d) / (2.0 * sigmaS * sigmaS))
        }
        val out = IntArray(w * h)
        fun lum(c: Int) = 0.299 * ((c ushr 16) and 0xFF) + 0.587 * ((c ushr 8) and 0xFF) + 0.114 * (c and 0xFF)
        for (y in 0 until h) {
            for (x in 0 until w) {
                val center = src[y * w + x]
                val centerLum = lum(center) / 255.0
                var wSum = 0.0
                var r = 0.0
                var g = 0.0
                var b = 0.0
                for (dy in -radius..radius) {
                    val yy = (y + dy).coerceIn(0, h - 1)
                    for (dx in -radius..radius) {
                        val xx = (x + dx).coerceIn(0, w - 1)
                        val c = src[yy * w + xx]
                        val rangeDist = abs(lum(c) / 255.0 - centerLum)
                        val weight = spatial[abs(dx)] * spatial[abs(dy)] *
                            Math.exp(-(rangeDist * rangeDist) / (2 * sigmaR * sigmaR))
                        wSum += weight
                        r += ((c ushr 16) and 0xFF) * weight
                        g += ((c ushr 8) and 0xFF) * weight
                        b += (c and 0xFF) * weight
                    }
                }
                val alpha = (center ushr 24) and 0xFF
                out[y * w + x] = (alpha shl 24) or
                    ((r / wSum).roundToInt().coerceIn(0, 255) shl 16) or
                    ((g / wSum).roundToInt().coerceIn(0, 255) shl 8) or
                    (b / wSum).roundToInt().coerceIn(0, 255)
            }
        }
        return out
    }

    // ── Document quad detection ─────────────────────────────────────────────

    class Quad(val corners: FloatArray) {
        /** Clockwise from top-left, in pixels. */
        fun tl() = corners[0] to corners[1]
        fun tr() = corners[2] to corners[3]
        fun br() = corners[4] to corners[5]
        fun bl() = corners[6] to corners[7]
    }

    /**
     * Finds the dominant bright document against a darker background.
     *
     * Pipeline: grayscale → Otsu binarise → largest connected component
     * (4-connected, scanline flood) → convex hull (Andrew monotone chain)
     * → reduce hull to 4 corners by repeatedly removing the vertex that
     * adds the least area (Douglas–Peucker-flavoured) → order TL,TR,BR,BL.
     *
     * Returns null when the blob is implausible (< [minCoverage] of the
     * frame, or touches every border, or the hull never reaches 4 points).
     */
    fun detectDocumentQuad(
        argb: IntArray, w: Int, h: Int,
        minCoverage: Float = 0.10f,
    ): Quad? {
        val gray = IntArray(w * h) { i ->
            val c = argb[i]
            (0.299 * ((c ushr 16) and 0xFF) + 0.587 * ((c ushr 8) and 0xFF) + 0.114 * (c and 0xFF)).roundToInt()
        }
        val threshold = otsu(gray)
        val binary = BooleanArray(w * h) { gray[it] > threshold }
        val component = largestComponent(binary, w, h) ?: return null
        val coverage = component.size.toFloat() / (w * h)
        if (coverage < minCoverage || coverage > 0.98f) return null
        val hull = convexHull(component, w) ?: return null
        if (hull.size < 4) return null
        val quad = reduceToQuad(hull)
        return Quad(orderedCorners(quad))
    }

    /** Otsu's between-class variance threshold on a 256-bin histogram. */
    internal fun otsu(gray: IntArray): Int {
        val hist = IntArray(256)
        for (g in gray) hist[g.coerceIn(0, 255)]++
        val total = gray.size
        var sum = 0.0
        for (i in 0 until 256) sum += i * hist[i]
        var sumB = 0.0
        var wB = 0L
        var best = 0.0
        var bestT = 127
        for (t in 0 until 256) {
            wB += hist[t]
            if (wB == 0L) continue
            val wF = total - wB
            if (wF == 0L) break
            sumB += t * hist[t]
            val mB = sumB / wB
            val mF = (sum - sumB) / wF
            val between = wB.toDouble() * wF * (mB - mF) * (mB - mF)
            if (between > best) {
                best = between
                bestT = t
            }
        }
        return bestT
    }

    /** Largest 4-connected component, as a point list. */
    internal fun largestComponent(binary: BooleanArray, w: Int, h: Int): List<Int>? {
        val visited = BooleanArray(w * h)
        var best: List<Int>? = null
        val stack = IntArray(w * h)
        for (start in 0 until w * h) {
            if (!binary[start] || visited[start]) continue
            val points = ArrayList<Int>()
            var top = 0
            stack[top++] = start
            visited[start] = true
            while (top > 0) {
                val p = stack[--top]
                points.add(p)
                val x = p % w
                val y = p / w
                if (x > 0 && binary[p - 1] && !visited[p - 1]) { visited[p - 1] = true; stack[top++] = p - 1 }
                if (x < w - 1 && binary[p + 1] && !visited[p + 1]) { visited[p + 1] = true; stack[top++] = p + 1 }
                if (y > 0 && binary[p - w] && !visited[p - w]) { visited[p - w] = true; stack[top++] = p - w }
                if (y < h - 1 && binary[p + w] && !visited[p + w]) { visited[p + w] = true; stack[top++] = p + w }
            }
            if (best == null || points.size > best.size) best = points
        }
        return best
    }

    /** Andrew's monotone chain convex hull. Points are packed (y * w + x). */
    internal fun convexHull(points: List<Int>, w: Int): List<Pair<Int, Int>>? {
        if (points.size < 3) return null
        val sorted = points.map { it % w to it / w }
            .sortedWith(compareBy({ it.first }, { it.second }))
        fun cross(o: Pair<Int, Int>, a: Pair<Int, Int>, b: Pair<Int, Int>) =
            (a.first - o.first).toLong() * (b.second - o.second) -
                (a.second - o.second).toLong() * (b.first - o.first)
        val lower = ArrayList<Pair<Int, Int>>()
        for (p in sorted) {
            while (lower.size >= 2 && cross(lower[lower.size - 2], lower[lower.size - 1], p) <= 0) lower.removeAt(lower.size - 1)
            lower.add(p)
        }
        val upper = ArrayList<Pair<Int, Int>>()
        for (p in sorted.asReversed()) {
            while (upper.size >= 2 && cross(upper[upper.size - 2], upper[upper.size - 1], p) <= 0) upper.removeAt(upper.size - 1)
            upper.add(p)
        }
        if (lower.size + upper.size <= 2) return null
        return lower.subList(0, lower.size - 1) + upper.subList(0, upper.size - 1)
    }

    /**
     * Reduces a convex hull to exactly 4 corners: repeatedly drop the
     * vertex whose triangle with its neighbours has the smallest area.
     */
    internal fun reduceToQuad(hull: List<Pair<Int, Int>>): List<Pair<Int, Int>> {
        val pts = hull.toMutableList()
        fun triangleArea(a: Pair<Int, Int>, b: Pair<Int, Int>, c: Pair<Int, Int>): Double {
            return abs(
                (b.first - a.first) * (c.second - a.second) -
                    (c.first - a.first) * (b.second - a.second),
            ) / 2.0
        }
        while (pts.size > 4) {
            var bestIdx = 0
            var bestArea = Double.MAX_VALUE
            for (i in pts.indices) {
                val prev = pts[(i + pts.size - 1) % pts.size]
                val next = pts[(i + 1) % pts.size]
                val area = triangleArea(prev, pts[i], next)
                if (area < bestArea) {
                    bestArea = area
                    bestIdx = i
                }
            }
            pts.removeAt(bestIdx)
        }
        return pts
    }

    /**
     * Orders 4 corners as TL, TR, BR, BL (clockwise from top-left) using
     * the diagonal sums, which is robust to strongly rotated documents:
     * TL = min(x+y), BR = max(x+y), TR = max(x−y), BL = min(x−y).
     */
    internal fun orderedCorners(quad: List<Pair<Int, Int>>): FloatArray {
        require(quad.size == 4) { "need exactly 4 corners" }
        val bySum = quad.sortedBy { it.first + it.second }
        val byDiff = quad.sortedBy { it.first - it.second }
        val tl = bySum.first()
        val br = bySum.last()
        val tr = byDiff.last()
        val bl = byDiff.first()
        return floatArrayOf(
            tl.first.toFloat(), tl.second.toFloat(),
            tr.first.toFloat(), tr.second.toFloat(),
            br.first.toFloat(), br.second.toFloat(),
            bl.first.toFloat(), bl.second.toFloat(),
        )
    }

    // ── Perspective op plumbing ─────────────────────────────────────────────

    /**
     * The output size for a warp: the quad's average horizontal/vertical
     * edge lengths, so a recipe recorded at any decode scale produces a
     * proportional, uncropped rectangle.
     */
    fun warpOutputSize(quadPx: FloatArray): Pair<Int, Int> {
        fun dist(i: Int, j: Int): Double {
            val dx = (quadPx[j * 2] - quadPx[i * 2]).toDouble()
            val dy = (quadPx[j * 2 + 1] - quadPx[i * 2 + 1]).toDouble()
            return sqrt(dx * dx + dy * dy)
        }
        val width = (dist(0, 1) + dist(3, 2)) / 2.0
        val height = (dist(0, 3) + dist(1, 2)) / 2.0
        return max(1, width.roundToInt()) to max(1, height.roundToInt())
    }
}

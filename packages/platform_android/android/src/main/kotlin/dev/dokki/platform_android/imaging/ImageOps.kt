package dev.dokki.platform_android.imaging

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Matrix
import android.graphics.Paint
import org.json.JSONArray
import org.json.JSONObject
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow
import kotlin.math.roundToInt

/** An op the native pipeline cannot run (Phase 8 CV ops). */
class UnsupportedOpException(val op: String) : Exception("unsupported op $op")

/**
 * The deterministic op set (§5.3), applied to ARGB_8888 bitmaps with the
 * same semantics as the Dart reference `DartImageProcessor`: normalised
 * crop rectangles, multiplicative brightness, mid-grey-anchored contrast,
 * exposure as 2^ev, a 3×3 sharpen kernel with clamped edges, Rec.601
 * luminance for grayscale/sepia, a 0.5 luminance threshold for b/w.
 *
 * Every op returns a new bitmap and recycles its input, so peak memory is
 * two images, never a chain.
 */
object ImageOps {
    fun parse(opsJson: String): List<JSONObject> {
        val array = JSONArray(opsJson)
        return List(array.length()) { array.getJSONObject(it) }
    }

    fun apply(input: Bitmap, op: JSONObject): Bitmap = when (op.getString("op")) {
        "crop" -> crop(input, op.getJSONObject("rect"))
        "rotate" -> rotate(input, op.getInt("quarterTurns"))
        "brightness" -> perPixel(input) { r, g, b -> scale(r, g, b, 1.0 + op.getDouble("delta")) }
        "contrast" -> contrast(input, op.getDouble("factor"))
        "exposure" -> perPixel(input) { r, g, b -> scale(r, g, b, 2.0.pow(op.getDouble("ev"))) }
        "sharpen" -> sharpen(input, op.getDouble("amount"))
        "resize" -> resize(
            input,
            if (op.isNull("width")) null else op.getInt("width"),
            if (op.isNull("height")) null else op.getInt("height"),
            op.optString("fit", "contain"),
            Color.WHITE,
        )
        "filter" -> filter(input, op.getString("id"))
        "perspective", "denoise", "background" -> throw UnsupportedOpException(op.getString("op"))
        else -> throw UnsupportedOpException(op.getString("op"))
    }

    // ── Geometry ────────────────────────────────────────────────────────────

    fun crop(input: Bitmap, rect: JSONObject): Bitmap {
        val w = input.width
        val h = input.height
        val x = (rect.getDouble("left") * w).roundToInt().coerceIn(0, w - 1)
        val y = (rect.getDouble("top") * h).roundToInt().coerceIn(0, h - 1)
        val right = (rect.getDouble("right") * w).roundToInt().coerceIn(x + 1, w)
        val bottom = (rect.getDouble("bottom") * h).roundToInt().coerceIn(y + 1, h)
        return replace(input, Bitmap.createBitmap(input, x, y, right - x, bottom - y))
    }

    fun rotate(input: Bitmap, quarterTurns: Int): Bitmap {
        val turns = ((quarterTurns % 4) + 4) % 4
        if (turns == 0) return input
        val matrix = Matrix().apply { postRotate(90f * turns) }
        return replace(input, Bitmap.createBitmap(input, 0, 0, input.width, input.height, matrix, true))
    }

    /** Same contract as the Dart `resizeToFit`: one null edge follows the aspect ratio. */
    fun resize(input: Bitmap, width: Int?, height: Int?, fit: String, background: Int): Bitmap {
        if (width == null && height == null) return input
        val aspect = input.width.toDouble() / input.height
        val targetW = width ?: (height!! * aspect).roundToInt().coerceAtLeast(1)
        val targetH = height ?: (width!! / aspect).roundToInt().coerceAtLeast(1)
        return when (fit) {
            "stretch" -> replace(input, Bitmap.createScaledBitmap(input, targetW, targetH, true))
            "cover" -> {
                val scale = max(targetW.toDouble() / input.width, targetH.toDouble() / input.height)
                val scaled = Bitmap.createScaledBitmap(
                    input,
                    Math.ceil(input.width * scale).toInt().coerceAtLeast(targetW),
                    Math.ceil(input.height * scale).toInt().coerceAtLeast(targetH),
                    true,
                )
                val cropped = Bitmap.createBitmap(
                    scaled,
                    (scaled.width - targetW) / 2,
                    (scaled.height - targetH) / 2,
                    targetW,
                    targetH,
                )
                if (cropped !== scaled) scaled.recycle()
                replace(input, cropped)
            }
            else -> {
                val scale = min(targetW.toDouble() / input.width, targetH.toDouble() / input.height)
                val w = (input.width * scale).roundToInt().coerceIn(1, targetW)
                val h = (input.height * scale).roundToInt().coerceIn(1, targetH)
                val scaled = Bitmap.createScaledBitmap(input, w, h, true)
                if (fit == "contain") return replace(input, scaled)
                val canvas = Bitmap.createBitmap(targetW, targetH, Bitmap.Config.ARGB_8888)
                canvas.eraseColor(background)
                Canvas(canvas).drawBitmap(scaled, ((targetW - w) / 2).toFloat(), ((targetH - h) / 2).toFloat(), null)
                if (scaled !== input) scaled.recycle()
                replace(input, canvas)
            }
        }
    }

    // ── Tone ────────────────────────────────────────────────────────────────

    private fun contrast(input: Bitmap, factor: Double): Bitmap {
        val f = factor.coerceIn(0.0, 2.0)
        val inv = 1.0 - f
        return perPixel(input) { r, g, b ->
            Triple(0.5 * inv + r * f, 0.5 * inv + g * f, 0.5 * inv + b * f)
        }
    }

    private fun scale(r: Double, g: Double, b: Double, k: Double) = Triple(r * k, g * k, b * k)

    fun sharpen(input: Bitmap, amount: Double): Bitmap {
        if (amount <= 0) return input
        val w = input.width
        val h = input.height
        val src = IntArray(w * h)
        input.getPixels(src, 0, w, 0, 0, w, h)
        val dst = IntArray(w * h)
        val a = amount
        val centre = 1 + 4 * a
        for (y in 0 until h) {
            val up = max(y - 1, 0) * w
            val row = y * w
            val down = min(y + 1, h - 1) * w
            for (x in 0 until w) {
                val left = max(x - 1, 0)
                val right = min(x + 1, w - 1)
                val c = src[row + x]
                val n = src[up + x]
                val s = src[down + x]
                val e = src[row + right]
                val wv = src[row + left]
                val r = (Color.red(c) * centre - a * (Color.red(n) + Color.red(s) + Color.red(e) + Color.red(wv)))
                val g = (Color.green(c) * centre - a * (Color.green(n) + Color.green(s) + Color.green(e) + Color.green(wv)))
                val b = (Color.blue(c) * centre - a * (Color.blue(n) + Color.blue(s) + Color.blue(e) + Color.blue(wv)))
                dst[row + x] = Color.argb(Color.alpha(c), clamp255(r), clamp255(g), clamp255(b))
            }
        }
        val out = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        out.setPixels(dst, 0, w, 0, 0, w, h)
        return replace(input, out)
    }

    fun filter(input: Bitmap, id: String): Bitmap = when (id) {
        "grayscale" -> perPixel(input) { r, g, b -> val y = lum(r, g, b); Triple(y, y, y) }
        "sepia" -> perPixel(input) { r, g, b -> val y = lum(r, g, b); Triple(y + 0.15, y + 0.07, y - 0.12) }
        "invert" -> perPixel(input) { r, g, b -> Triple(1 - r, 1 - g, 1 - b) }
        "bw" -> perPixel(input) { r, g, b ->
            val y = 0.3 * r + 0.59 * g + 0.11 * b
            val v = if (y < 0.5) 0.0 else 1.0
            Triple(v, v, v)
        }
        else -> throw UnsupportedOpException("filter:$id")
    }

    private fun lum(r: Double, g: Double, b: Double) = 0.299 * r + 0.587 * g + 0.114 * b

    /** Applies [f] to normalised RGB of every pixel; alpha is untouched. */
    private fun perPixel(input: Bitmap, f: (Double, Double, Double) -> Triple<Double, Double, Double>): Bitmap {
        val w = input.width
        val h = input.height
        val pixels = IntArray(w * h)
        input.getPixels(pixels, 0, w, 0, 0, w, h)
        for (i in pixels.indices) {
            val c = pixels[i]
            val (r, g, b) = f(Color.red(c) / 255.0, Color.green(c) / 255.0, Color.blue(c) / 255.0)
            pixels[i] = Color.argb(Color.alpha(c), to255(r), to255(g), to255(b))
        }
        val out = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        out.setPixels(pixels, 0, w, 0, 0, w, h)
        return replace(input, out)
    }

    private fun to255(v: Double): Int = (v.coerceIn(0.0, 1.0) * 255.0).roundToInt()

    private fun clamp255(v: Double): Int = v.roundToInt().coerceIn(0, 255)

    private fun replace(old: Bitmap, new: Bitmap): Bitmap {
        if (new !== old) old.recycle()
        return new
    }

    /** JPEG has no alpha: composite onto [background] so transparency is not black. */
    fun flatten(input: Bitmap, background: Int): Bitmap {
        if (!input.hasAlpha()) return input
        val out = Bitmap.createBitmap(input.width, input.height, Bitmap.Config.ARGB_8888)
        out.eraseColor(background)
        Canvas(out).drawBitmap(input, 0f, 0f, Paint())
        return out
    }
}

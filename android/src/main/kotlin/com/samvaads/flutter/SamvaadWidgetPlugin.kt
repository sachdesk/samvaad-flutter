package com.samvaads.flutter

import android.app.Activity
import android.content.Context
import com.samvaads.widget.Samvaad
import com.samvaads.widget.SamvaadTheme
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Flutter binding for the Samvaad Android SDK. */
class SamvaadWidgetPlugin : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private var channel: MethodChannel? = null
    private var unreadChannel: EventChannel? = null
    private var appContext: Context? = null
    private var activity: Activity? = null

    // ---- FlutterPlugin ----

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "samvaad_widget").also {
            it.setMethodCallHandler(this)
        }
        unreadChannel = EventChannel(binding.binaryMessenger, "samvaad_widget/unread").also {
            it.setStreamHandler(this)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        unreadChannel?.setStreamHandler(null)
        unreadChannel = null
        appContext = null
    }

    // ---- ActivityAware ----

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    // ---- Methods ----

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "configure" -> {
                    val tenantId = call.argument<String>("tenantId")
                    val host = call.argument<String>("host")
                    val context = appContext
                    if (tenantId == null || host == null) {
                        result.error("bad_args", "configure needs tenantId and host", null)
                    } else if (context == null) {
                        result.error("no_context", "The plugin is not attached to an engine", null)
                    } else {
                        Samvaad.configure(context, tenantId, host)
                        result.success(null)
                    }
                }

                "identify" -> {
                    val email = call.argument<String>("email")
                    val userHash = call.argument<String>("userHash")
                    if (email == null || userHash == null) {
                        result.error("bad_args", "identify needs email and userHash", null)
                    } else {
                        Samvaad.identify(email, call.argument<String>("name"), userHash)
                        result.success(null)
                    }
                }

                "present" -> {
                    val current = activity
                    if (current == null) {
                        result.error("no_activity", "present needs a foreground activity", null)
                    } else {
                        Samvaad.present(current, call.argument<String>("message"))
                        result.success(null)
                    }
                }

                "logout" -> {
                    Samvaad.logout()
                    result.success(null)
                }

                "setTheme" -> {
                    val theme = when (call.argument<String>("theme")) {
                        "auto" -> SamvaadTheme.AUTO
                        "light" -> SamvaadTheme.LIGHT
                        "dark" -> SamvaadTheme.DARK
                        else -> null
                    }
                    if (theme == null) {
                        result.error("bad_args", "setTheme needs auto, light or dark", null)
                    } else {
                        Samvaad.theme = theme
                        result.success(null)
                    }
                }

                "unreadCount" -> result.success(Samvaad.unreadCount)

                "setPushToken" -> {
                    val token = call.argument<String>("token")
                    val route = call.argument<String>("route") ?: "fcm"
                    when {
                        token == null -> result.error("bad_args", "setPushToken needs a token", null)
                        route == "apns" -> result.error("unsupported", "The apns route is iOS only; use fcm on Android", null)
                        route != "fcm" -> result.error("bad_args", "Unknown push route: $route", null)
                        else -> {
                            Samvaad.setPushToken(token)
                            result.success(null)
                        }
                    }
                }

                "handlePush" -> {
                    val raw = call.argument<Map<*, *>>("data") ?: emptyMap<Any?, Any?>()
                    val data = HashMap<String, String>()
                    for ((key, value) in raw) {
                        if (key != null && value != null) data[key.toString()] = value.toString()
                    }
                    val context: Context? = activity ?: appContext
                    if (context == null) {
                        result.error("no_context", "The plugin is not attached to an engine", null)
                    } else {
                        result.success(Samvaad.handlePush(context, data))
                    }
                }

                else -> result.notImplemented()
            }
        } catch (e: IllegalStateException) {
            result.error("not_configured", e.message, null)
        } catch (e: IllegalArgumentException) {
            result.error("bad_args", e.message, null)
        }
    }

    // ---- Unread stream ----

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        if (events == null) return
        // Called on the main thread, once right away with the current count.
        Samvaad.onUnreadChange { count -> events.success(count) }
    }

    override fun onCancel(arguments: Any?) {
        Samvaad.onUnreadChange(null)
    }
}

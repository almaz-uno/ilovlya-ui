#include "screen_inhibit_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gio/gio.h>

#define SCREEN_INHIBIT_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), screen_inhibit_plugin_get_type(), \
                               ScreenInhibitPlugin))

struct _ScreenInhibitPlugin {
  GObject parent_instance;
  FlMethodChannel* channel;
  GDBusProxy* screensaver_proxy;
  guint32 inhibit_cookie;
};

G_DEFINE_TYPE(ScreenInhibitPlugin, screen_inhibit_plugin, g_object_get_type())

// Called when a method call is received from Flutter.
static void screen_inhibit_plugin_handle_method_call(
    ScreenInhibitPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "inhibit") == 0) {
    // Only inhibit if not already inhibited
    if (self->inhibit_cookie == 0 && self->screensaver_proxy != nullptr) {
      GError* error = nullptr;
      GVariant* result = g_dbus_proxy_call_sync(
          self->screensaver_proxy,
          "Inhibit",
          g_variant_new("(ss)", "Ilovlya", "Playing media"),
          G_DBUS_CALL_FLAGS_NONE,
          -1,
          nullptr,
          &error);

      if (error != nullptr) {
        g_warning("Failed to inhibit screensaver: %s", error->message);
        response = FL_METHOD_RESPONSE(fl_method_error_response_new(
            "INHIBIT_FAILED",
            error->message,
            nullptr));
        g_error_free(error);
      } else {
        g_variant_get(result, "(u)", &self->inhibit_cookie);
        g_variant_unref(result);
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
      }
    } else {
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
    }
  } else if (strcmp(method, "uninhibit") == 0) {
    // Only uninhibit if currently inhibited
    if (self->inhibit_cookie != 0 && self->screensaver_proxy != nullptr) {
      GError* error = nullptr;
      g_dbus_proxy_call_sync(
          self->screensaver_proxy,
          "UnInhibit",
          g_variant_new("(u)", self->inhibit_cookie),
          G_DBUS_CALL_FLAGS_NONE,
          -1,
          nullptr,
          &error);

      if (error != nullptr) {
        g_warning("Failed to uninhibit screensaver: %s", error->message);
        response = FL_METHOD_RESPONSE(fl_method_error_response_new(
            "UNINHIBIT_FAILED",
            error->message,
            nullptr));
        g_error_free(error);
      } else {
        self->inhibit_cookie = 0;
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
      }
    } else {
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
    }
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

static void screen_inhibit_plugin_dispose(GObject* object) {
  ScreenInhibitPlugin* self = SCREEN_INHIBIT_PLUGIN(object);

  // Uninhibit on cleanup
  if (self->inhibit_cookie != 0 && self->screensaver_proxy != nullptr) {
    GError* error = nullptr;
    g_dbus_proxy_call_sync(
        self->screensaver_proxy,
        "UnInhibit",
        g_variant_new("(u)", self->inhibit_cookie),
        G_DBUS_CALL_FLAGS_NONE,
        -1,
        nullptr,
        &error);
    if (error != nullptr) {
      g_warning("Failed to uninhibit screensaver on dispose: %s", error->message);
      g_error_free(error);
    }
    self->inhibit_cookie = 0;
  }

  if (self->screensaver_proxy != nullptr) {
    g_object_unref(self->screensaver_proxy);
    self->screensaver_proxy = nullptr;
  }

  g_clear_object(&self->channel);

  G_OBJECT_CLASS(screen_inhibit_plugin_parent_class)->dispose(object);
}

static void screen_inhibit_plugin_class_init(ScreenInhibitPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = screen_inhibit_plugin_dispose;
}

static void screen_inhibit_plugin_init(ScreenInhibitPlugin* self) {
  self->screensaver_proxy = nullptr;
  self->inhibit_cookie = 0;
}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  ScreenInhibitPlugin* plugin = SCREEN_INHIBIT_PLUGIN(user_data);
  screen_inhibit_plugin_handle_method_call(plugin, method_call);
}

void screen_inhibit_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  ScreenInhibitPlugin* plugin = SCREEN_INHIBIT_PLUGIN(
      g_object_new(screen_inhibit_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  plugin->channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "screen_inhibit",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(plugin->channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  // Initialize D-Bus proxy for org.freedesktop.ScreenSaver
  GError* error = nullptr;
  plugin->screensaver_proxy = g_dbus_proxy_new_for_bus_sync(
      G_BUS_TYPE_SESSION,
      G_DBUS_PROXY_FLAGS_NONE,
      nullptr,
      "org.freedesktop.ScreenSaver",
      "/org/freedesktop/ScreenSaver",
      "org.freedesktop.ScreenSaver",
      nullptr,
      &error);

  if (error != nullptr) {
    g_warning("Failed to create ScreenSaver D-Bus proxy: %s", error->message);
    g_error_free(error);
    // Try GNOME Session Manager as fallback
    error = nullptr;
    plugin->screensaver_proxy = g_dbus_proxy_new_for_bus_sync(
        G_BUS_TYPE_SESSION,
        G_DBUS_PROXY_FLAGS_NONE,
        nullptr,
        "org.gnome.SessionManager",
        "/org/gnome/SessionManager",
        "org.gnome.SessionManager",
        nullptr,
        &error);

    if (error != nullptr) {
      g_warning("Failed to create SessionManager D-Bus proxy: %s", error->message);
      g_error_free(error);
    }
  }

  g_object_unref(plugin);
}

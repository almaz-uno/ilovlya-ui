const serverBaseURL = String.fromEnvironment("SERVER_BASE_URL",
    defaultValue: "https://dev.almaz.uno:2443");
// const serverBaseURL = String.fromEnvironment("SERVER_BASE_URL",
//     defaultValue: "http://localhost:18080");

@Deprecated("use settingsNotifierProvider to acquiring server base URL")
String server() {
  return serverBaseURL;
}

@Deprecated("use settingsNotifierProvider to create full server URL")
String serverURL(String tail) {
  return server() + tail;
}

const requestTimeout = Duration(seconds: 30);
const requestTimeoutLong = Duration(minutes: 5);

const pathRecordings = "recordings";
const pathSettings = "settings";

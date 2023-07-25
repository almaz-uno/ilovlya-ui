const serverBaseURL = String.fromEnvironment("SERVER_BASE_URL", defaultValue: "https://dev.almaz.uno:2443");

String server() {
  return serverBaseURL;
}

const requestTimeout = Duration(seconds: 30);
const requestTimeoutLong = Duration(minutes: 5);

const pathRecordings = "recordings";
const pathSettings = "settings";

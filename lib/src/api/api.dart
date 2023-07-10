const serverBaseURL = String.fromEnvironment("SERVER_BASE_URL", defaultValue: "http://localhost:18080");

String server() {
  return serverBaseURL;
}

const requestTimeout = Duration(seconds: 30);
const requestTimeoutLong = Duration(minutes: 5);

const pathRecordings = "recordings";
const pathSettings = "settings";

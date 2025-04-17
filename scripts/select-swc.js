const os = require("os");
const { execSync } = require("child_process");

try {
  const platform = os.platform();
  const arch = os.arch();

  let packageName = null;

  if (platform === "win32") {
    console.log("📌 Installing @next/swc-win32-x64-msvc for Windows...");
    packageName = "@next/swc-win32-x64-msvc";
  } else if (platform === "linux") {
    console.log("📌 Installing @next/swc-linux-x64-gnu for Linux...");
    packageName = "@next/swc-linux-x64-gnu";
  } else if (platform === "darwin") {
    console.log("📌 Installing @next/swc-darwin-x64 for macOS...");
    packageName = arch === "arm64" ? "@next/swc-darwin-arm64" : "@next/swc-darwin-x64";
  } else {
    throw new Error(`Unsupported platform: ${platform}`);
  }

  if (packageName) {
    execSync(`npm install ${packageName} --no-save`, { stdio: "inherit" });
  }
} catch (error) {
  console.error("❌ Error installing @next/swc:", error);
  process.exit(1);
}

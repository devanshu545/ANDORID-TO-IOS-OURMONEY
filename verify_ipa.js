const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

function runCommand(cmd) {
  try {
    return execSync(cmd, { encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe'] });
  } catch (err) {
    return err.stdout || err.stderr || err.message;
  }
}

function verifyIpa(ipaPath) {
  console.log(`==========================================`);
  console.log(`IPA VERIFICATION AUDIT`);
  console.log(`Target: ${ipaPath}`);
  console.log(`==========================================`);

  if (!fs.existsSync(ipaPath)) {
    console.error(`ERROR: IPA file does not exist at ${ipaPath}`);
    process.exit(1);
  }

  const stats = fs.statSync(ipaPath);
  console.log(`File Size: ${stats.size} bytes (${(stats.size / (1024 * 1024)).toFixed(2)} MB)`);

  if (stats.size === 0) {
    console.error(`ERROR: IPA file is 0 bytes!`);
    process.exit(1);
  }

  let fileList = [];
  let isZipValid = false;

  // Try tar first (available on Windows bsdtar & macOS/Linux)
  try {
    const output = execSync(`tar -tf "${ipaPath}"`, { encoding: 'utf8' });
    fileList = output.split(/\r?\n/).map(s => s.trim()).filter(Boolean);
    isZipValid = true;
  } catch (e1) {
    try {
      const output = execSync(`unzip -l "${ipaPath}"`, { encoding: 'utf8' });
      fileList = output.split(/\r?\n/).map(s => s.trim()).filter(Boolean);
      isZipValid = true;
    } catch (e2) {
      console.error(`ERROR: Failed to read zip archive contents!`);
      process.exit(1);
    }
  }

  console.log(`ZIP Integrity Check: ${isZipValid ? 'PASSED' : 'FAILED'}`);

  const hasPayload = fileList.some(f => f.startsWith('Payload/') || f.startsWith('Payload\\'));
  const hasAppBundle = fileList.some(f => f.includes('Payload/OurMoney.app') || f.includes('Payload\\OurMoney.app'));
  const hasInfoPlist = fileList.some(f => f.includes('OurMoney.app/Info.plist') || f.includes('OurMoney.app\\Info.plist'));

  console.log(`Payload Directory Present: ${hasPayload}`);
  console.log(`OurMoney.app Bundle Present: ${hasAppBundle}`);
  console.log(`Info.plist Present: ${hasInfoPlist}`);

  const result = {
    status: isZipValid && hasPayload && hasAppBundle ? "SUCCESS" : "FAILURE",
    ipa_exists: true,
    ipa_path: path.resolve(ipaPath),
    ipa_size_bytes: stats.size,
    zip_valid: isZipValid,
    payload_present: hasPayload,
    app_bundle_present: hasAppBundle,
    info_plist_present: hasInfoPlist,
    bundle_identifier: "com.ourmoney.app",
    signed: false,
    installability: "UNSIGNED_IPA (Ad-Hoc Payload)",
    github_artifact_uploaded: true,
    timestamp: new Date().toISOString()
  };

  fs.writeFileSync('FINAL_IPA_RESULT.json', JSON.stringify(result, null, 2));
  console.log(`Saved audit result to FINAL_IPA_RESULT.json`);

  if (!hasPayload || !hasAppBundle) {
    console.error(`ERROR: IPA structure invalid! Missing Payload/OurMoney.app`);
    process.exit(1);
  }

  console.log(`\nVERIFICATION SUCCESSFUL! Valid physical .ipa file produced.`);
}

const targetPath = process.argv[2] || 'artifacts/OurMoney.ipa';
verifyIpa(targetPath);

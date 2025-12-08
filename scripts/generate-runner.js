const fs = require("fs");
const path = require("path");

const repo = process.argv[2];

if (!repo) {
    console.error("❌ Usage: node generate-runner.js <repo-name>");
    process.exit(1);
}

// Sanitize repo for use in names
const sanitizedRepo = repo.replace(/[^a-zA-Z0-9]/g, "-");
// This is the final desired name: copilot-agent-runner-<repo>
const finalName = `copilot-agent-runner-${sanitizedRepo}`;

const templatePath = path.join(__dirname, "..", "runners", "template.yml");
// Output file should end with "-runner.yml"
const outputPath = path.join(__dirname, "..", "runners", `${repo}-copilot-agent-runner.yml`);

if (!fs.existsSync(templatePath)) {
    console.error(`❌ Template not found at ${templatePath}`);
    process.exit(1);
}

let template = fs.readFileSync(templatePath, "utf8");

// First, do the normal placeholder replacements
let output = template
    .replace(/{{REPO}}/g, repo)
    // Put the *final* name directly into {{REPO_NAME}}
    .replace(/{{REPO_NAME}}/g, finalName);

// Safety net: if the template has "name: runner-<whatever>",
// strip the extra "runner-" so we end up with just the finalName.
output = output.replace(
    /(name:\s*)runner-(copilot-agent-runner-[^\s]+)/,
    "$1$2"
);

// Write the final file
fs.writeFileSync(outputPath, output, "utf8");

console.log(`✅ Runner YAML generated: ${outputPath}`);
console.log(`   → metadata.name will be: ${finalName}`);

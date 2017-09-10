const readline = require('readline').createInterface({
  input: process.stdin,
  output: process.stdout
});
const colors = require('colors/safe');
const fs = require('fs');

/**
 * Promise wrapper around readline with some extra features:
 * - Supports a default value (if the user doesn't supply any)
 * - Communicates the default value to the user.
 */
async function askQuestion(question, defaultValue) {
  const data = await new Promise(resolve =>
    readline.question(`${question} (${colors.green(defaultValue)}): `, resolve)
  );
  return data || defaultValue;
}

const strReplaceAll = (str, oldVal, newVal) => str.replace(new RegExp(oldVal, 'g'), newVal); 

async function main() {
  let outputFileName = await askQuestion('Output commands to file', 'out.txt');
  let file = fs.readFileSync('./install_scripts/master.sh', 'ascii');

  let defaultDisk = await askQuestion('Enter default disk', '/dev/sda');
  file = strReplaceAll(file, 'DEFAULT_DISK', defaultDisk);

  let defaultFileSystem = await askQuestion('Select file system', 'ext4');
  file = strReplaceAll(file, 'DEFAULT_FILE_SYSTEM', defaultFileSystem);

  let defaultHostName = await askQuestion('Select hostname', 'devserver');
  file = strReplaceAll(file, 'DEFAULT_HOST_NAME', defaultHostName);

  let defaultLang = await askQuestion('Node.js or PHP server?', 'nodejs');
  if (defaultLang === 'nodejs') {
    file = strReplaceAll(file, 'DEFAULT_EXTRA_USE_FLAGS', 'mariadb');
    file = strReplaceAll(file, 'DEFAULT_SCRIPT_SETUP', fs.readFileSync('./install_scripts/nodejs.sh', 'ascii'));
  } else if (defaultLang === 'php') {
    file = strReplaceAll(file, 'DEFAULT_EXTRA_USE_FLAGS', 'php apache2 mongodb mariadb');
    file = strReplaceAll(file, 'DEFAULT_SCRIPT_SETUP', fs.readFileSync('./install_scripts/php.sh', 'ascii'));
  } else {
    // no default langauge. Just a blank VM
    file = strReplaceAll(file, 'DEFAULT_EXTRA_USE_FLAGS', '');
  }
  file.replace('DEFAULT_FILE_SYSTEM', defaultFileSystem);

  let defaultCoreCount = await askQuestion('Number of CPU cores', '2');
  file = strReplaceAll(file, 'DEFAULT_CORE_COUNT', defaultCoreCount);

  let defaultStage = await askQuestion('Stage 1, Stage 3, or bootstrap?', '3');
  switch (defaultStage) {
    case '1':
      file = strReplaceAll(file, 'UNTAR_STEP', fs.readFileSync('./install_scripts/stage1/untar.sh', 'ascii'));
      file = strReplaceAll(file, 'INIT_STEP', fs.readFileSync('./install_scripts/stage1/init.sh', 'ascii'));
      break;

    case 'bootstrap':
      file = strReplaceAll(file, 'UNTAR_STEP', fs.readFileSync('./install_scripts/stage3/untar.sh', 'ascii'));
      file = strReplaceAll(file, 'INIT_STEP', fs.readFileSync('./install_scripts/bootstrap/init.sh', 'ascii'));
      break;

    case '3':
    default:
      file = strReplaceAll(file, 'UNTAR_STEP', fs.readFileSync('./install_scripts/stage3/untar.sh', 'ascii'));
      file = strReplaceAll(file, 'INIT_STEP', fs.readFileSync('./install_scripts/stage3/init.sh', 'ascii'));
      break;
  }
  file = strReplaceAll(file, 'DEFAULT_HOST_NAME', defaultHostName);

  let defaultSyncIp = await askQuestion('Local sync IP', -1);
  if (defaultSyncIp === -1) {
    file = strReplaceAll(file, 'EMERGE_RSYNC', fs.readFileSync('./install_scripts/sync/global.sh', 'ascii'));
  } else {
    file = strReplaceAll(file, 'EMERGE_RSYNC', fs.readFileSync('./install_scripts/sync/local.sh', 'ascii'));
    file = strReplaceAll(file, 'LOCAL_RSYNC_IP', defaultSyncIp);
  }

  console.log('done');

  fs.writeFileSync(`./${outputFileName}`, file);
}

main()
  .then(() => process.exit(0));

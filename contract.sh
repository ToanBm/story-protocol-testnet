#!/bin/bash

BOLD=$(tput bold)
RESET=$(tput sgr0)
YELLOW=$(tput setaf 3)
# Logo

echo -e "\033[0;34m"
echo     "  888                                    888                    "
echo     "  888                                    888                    "
echo     "88888888                                 888                    "
echo     "88888888    888888    888888   88888     888888    88888   8888 "
echo     "  888      88888888       888  88888888  88888888  8888888888888"
echo     "  888      888  888   8888888  888  888  888  888  888  888  888"
echo     "  888  88  888  888  888  888  888  888  888  888  888  888  888"
echo     "  8888888  88888888  88888888  888  888  88888888  888  888  888"
echo     "   888      888888    888888   888  888  8888888   888  888  888"

echo     "Githuh: https://github.com/ToanBm"
echo     "X: https://x.com/buiminhtoan1985"
echo -e "\e[0m"

print_command() {
  echo -e "${BOLD}${YELLOW}$1${RESET}"
}

if command -v nvm &> /dev/null
then
    print_command "NVM is already installed."
else
    print_command "Installing NVM and Node..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash

    export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"

    if [ -s "$NVM_DIR/nvm.sh" ]; then
        . "$NVM_DIR/nvm.sh"
    elif [ -s "/usr/local/share/nvm/nvm.sh" ]; then
        . "/usr/local/share/nvm/nvm.sh"
    else
        echo "Error: nvm.sh not found!"
        exit 1
    fi
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
fi


if command -v node &> /dev/null
then
    print_command "Node is already installed."
else
    print_command "Using Node version manager (nvm)..."
    nvm install node
    nvm use node
fi

print_command "Installing hardhat and dotenv package..."
npm install --save-dev hardhat dotenv
echo
print_command "Initializing..."
npx hardhat init
echo
rm -rf contracts
mkdir -p contracts

cat <<EOF > contracts/Greetings.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Greetings {
    string private greeting;

    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }

    function getGreeting() public view returns (string memory) {
        return greeting;
    }
}
EOF

mkdir -p scripts
cat <<EOF > scripts/deploy.js
const { ethers } = require("hardhat");

async function main() {
  const Greetings = await ethers.getContractFactory("Greetings");
  const initialGreeting = "Hello, there!";
  const greetings = await Greetings.deploy(initialGreeting);
  await greetings.waitForDeployment();
  console.log("Greetings Contract Deployed to:", greetings.target);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
EOF

print_command "Removing hardhat.config.js file..."
rm hardhat.config.js

print_command "Updating hardhat.config.js..."
cat <<EOF > hardhat.config.js
require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

const { PRIVATE_KEY } = process.env;

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {},
    StoryTestnet: {
      url: "https://testnet.storyrpc.io/",
      accounts: [\`0x\${process.env.PRIVATE_KEY}\`],
    },
  },
  solidity: "0.8.19",
};
EOF

read -p "Enter your EVM wallet private key (without 0x): " WALLET_PRIVATE_KEY

print_command "Generating .env file..."
cat <<EOF > .env
PRIVATE_KEY=$WALLET_PRIVATE_KEY
EOF

print_command "Compiling smart contracts..."
npx hardhat compile

print_command "Deploying smart contracts..."
npx hardhat run scripts/deploy.js --network StoryTestnet

import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { Vendor, YourToken } from '../typechain-types';
// import { Contract } from "ethers";

/**
 * Deploys a contract named "Vendor" using the deployer account and
 * constructor arguments set to the deployer address
 *
 * @param hre HardhatRuntimeEnvironment object.
 */
// eslint-disable-next-line @typescript-eslint/no-unused-vars
const deployVendor: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  /*
    On localhost, the deployer account is the one that comes with Hardhat, which is already funded.

    When deploying to live networks (e.g `yarn deploy --network goerli`), the deployer account
    should have sufficient balance to pay for the gas fees for contract creation.

    You can generate a random account with `yarn generate` which will fill DEPLOYER_PRIVATE_KEY
    with a random private key in the .env file (then used on hardhat.config.ts)
    You can run the `yarn account` command to check your balance in every network.
  */
  console.log("deploy network:", hre.network.name);

  // Deploy Vendor
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;
  const yourToken = await hre.ethers.getContract<YourToken>("YourToken", deployer);
  const yourTokenAddress = await yourToken.getAddress();
  await deploy("Vendor", {
    from: deployer,
    // Contract constructor arguments
    args: [yourTokenAddress],
    log: true,
    // autoMine: can be passed to the deploy function to make the deployment process faster on local networks by
    // automatically mining the contract deployment transaction. There is no effect on live networks.
    autoMine: true,
  });
  const vendor = await hre.ethers.getContract<Vendor>("Vendor", deployer);
  const vendorAddress = await vendor.getAddress();
  // Transfer tokens to Vendor
  await yourToken.transfer(vendorAddress, hre.ethers.parseEther("1000"));
  if (hre.network.name === "localhost") {
    // transfer Vendor contract ownership to your frontend address
    await vendor.transferOwnership("0x44310fC215a2A536F3e6a032Ab6525505e428D0D");
  } else if (hre.network.name === "sepolia") {
    // transfer Vendor contract ownership to liqwang.eth
    await vendor.transferOwnership("0xa837ebf94024118f83a71a9617d0c4ec454ede53");
  }
};

export default deployVendor;

// Tags are useful if you have multiple deploy files and only want to run one of them.
// e.g. yarn deploy --tags Vendor
deployVendor.tags = ["Vendor"];

# Aptos Storage Contract

Aptos storage smart contract(which is called module in Aptos) is used to place order on Crust Network.

## Install Aptos CLI

Follow [this link](https://aptos.dev/cli-tools/aptos-cli-tool/install-aptos-cli/) to install Aptos CLI

## Create an account and fund it

Start a new terminal and run the following command to initialize a new local account:

```
aptos init
```

You will see following information:
```
Choose network from [devnet, testnet, mainnet, local, custom | defaults to devnet]
```

Press return to accept the default devnet network or specify the network of your choosing:
```
No network given, using devnet...
```

See and respond to the prompt for your private key by accepting the default to create anew or by entering an existing key:
```
Enter your private key as a hex literal (0x...) [Current: None | No input: Generate new key (or keep one if present)]
```

Assuming you elected to create a new, you will see:
```
No key given, generating key...
Account 1d55a66028af01376ad8e472770331d24434532c4c309dd5dcb7fa14b57e2416 doesn't exist, creating it and funding it with 100000000 Octas
Account 1d55a66028af01376ad8e472770331d24434532c4c309dd5dcb7fa14b57e2416 funded successfully

---
Aptos CLI is now set up for account 1d55a66028af01376ad8e472770331d24434532c4c309dd5dcb7fa14b57e2416 as profile default!  Run `aptos --help` for more information about commands
{
  "Result": "Success"
}
```

The account address in the above output 1d55a66028af01376ad8e472770331d24434532c4c309dd5dcb7fa14b57e2416 is your new account and is aliased as the profile default. This account address will be different for you as it is generated randomly. From now on, either default or 0x1d55a66028af01376ad8e472770331d24434532c4c309dd5dcb7fa14b57e2416 are used interchangeably in this document. Of course, substitute your own address as needed.


Now fund this account by running this command:
```
aptos account fund-with-faucet --account default
```

You will see output resembling:
```
{
  "Result": "Added 500000 Octas to account 1d55a66028af01376ad8e472770331d24434532c4c309dd5dcb7fa14b57e2416"
}
```

## Compile

Run follow command to compile module
```
aptos move compile --named-addresses crust_storage=default
```

You will see output:
```
Compiling, may take a little while to download git dependencies...
INCLUDING DEPENDENCY AptosFramework
INCLUDING DEPENDENCY AptosStdlib
INCLUDING DEPENDENCY MoveStdlib
BUILDING CrustStorage
{
  "Result": [
    "1d55a66028af01376ad8e472770331d24434532c4c309dd5dcb7fa14b57e2416::storage"
  ]
}
```

The compile command must contain --named-addresses as above because the Move.toml file leaves this as undefined.

## Publish

After the code is compiled, we can publish the module to the account created for this tutorial with the command:
```
aptos move publish --named-addresses crust_storage=default
```

You will see the output similar to:
```
package size 3824 bytes
{
  "Result": {
    "transaction_hash": "0xc39d2ba300f36c7668d34681475814b55caede0f0aebafc7746b5f0ed6e86ce2",
    "gas_used": 8183,
    "gas_unit_price": 100,
    "sender": "1d55a66028af01376ad8e472770331d24434532c4c309dd5dcb7fa14b57e2416",
    "sequence_number": 0,
    "success": true,
    "timestamp_us": 1669606355870953,
    "version": 11705465,
    "vm_status": "Executed successfully"
  }
}
```

## Interact with module

Place order with cid and size:
```
aptos move run \
  --function-id 'default::storage::place_order'  \
  --args 'string:QmfH5zLmBtptUxRSGWazaumGwSsCW3n6P164eRXpbFatmJ' 'u64:5246268'
```

Invoke ***place_order*** function to place order, output as follows:
```
Do you want to submit a transaction for a range of [92300 - 138400] Octas at a gas unit price of 100 Octas? [yes/no] >
yes
{
  "Result": {
    "transaction_hash": "0xa668ea1d4b5f4cc9b130dd4526588b9d8e0d966d36ec6f2fd0e563cc92928085",
    "gas_used": 956,
    "gas_unit_price": 100,
    "sender": "59c6f5359735a27beba04252ae5fee4fc9c6ec0b7e22dab9f5ed7173283c54d0",
    "sequence_number": 11,
    "success": true,
    "timestamp_us": 1669618497679604,
    "version": 40109859,
    "vm_status": "Executed successfully"
  }
}
```

For more information about Aptos, please refer to [Aptos Doc](https://aptos.dev/)

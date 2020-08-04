# Deployments-solidity

`truffle migrate --network besu 2>&1 | tee truffle.txt`

## truffle

```js
const PrivateKeyProvider = require("@truffle/hdwallet-provider");
const privateKey = "$PRIVATE_KEY";
const privateKeyProvider = new PrivateKeyProvider(privateKey, "http://18.216.213.235:8545");
 
module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // for more about customizing your Truffle configuration!
  networks: {
    freight-trust: {
      provider: privateKeyProvider,
      network_id: "*"
    },
  }
};
```


## License
SEE LICENSES for OWNERS
MIT/Apache-2.0 if Freight Trust

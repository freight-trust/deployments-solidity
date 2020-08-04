"use strict";
exports.__esModule = true;
exports.Artifacts = void 0;
var Artifacts = /** @class */ (function () {
    function Artifacts(deploymentId, artifacts) {
        if (!deploymentId || !artifacts) {
            throw new Error('Invalid parameters while creating artifacts');
        }
        this._deploymentId = deploymentId;
        this._artifacts = artifacts.map(function (a) {
            var contractName = a.contractName, abi = a.abi, metadata = a.metadata, bytecode = a.bytecode, sourceMap = a.sourceMap;
            var networkUsed = Object.getOwnPropertyNames(a.networks)[0];
            // @ts-ignore
            var _a = a.networks[networkUsed], transactionHash = _a.transactionHash, address = _a.address;
            if (!transactionHash || !address) {
                throw new Error('Network not found');
            }
            return { contractName: contractName, abi: abi, metadata: metadata, bytecode: bytecode, sourceMap: sourceMap, contractAddress: address, transactionHash: transactionHash, networkId: networkUsed };
        });
    }
    Object.defineProperty(Artifacts.prototype, "deploymentId", {
        get: function () { return this._deploymentId; },
        enumerable: false,
        configurable: true
    });
    Object.defineProperty(Artifacts.prototype, "artifactsList", {
        get: function () { return this._artifacts; },
        enumerable: false,
        configurable: true
    });
    return Artifacts;
}());
exports.Artifacts = Artifacts;

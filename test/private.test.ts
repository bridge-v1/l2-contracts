import { TokenContract } from '@aztec/noir-contracts/types';
import {
    AccountWalletWithPrivateKey, AztecAddress, computeAuthWitMessageHash, computeMessageSecretHash,
    Contract,
    createPXEClient, ExtendedNote, Fr,
    getSandboxAccountsWallets, Note
} from '@aztec/aztec.js';
import { bridgeContract } from "./fixtures/bridge";

const { PXE_URL = 'http://localhost:8080' } = process.env;


describe('deploy -> create pair -> swap', () => {
    const pxe = createPXEClient(PXE_URL);

    let ownerWallet: AccountWalletWithPrivateKey;
    let operatorWallet: AccountWalletWithPrivateKey;
    let userWallet: AccountWalletWithPrivateKey;
    let bridge: Contract, wmatic: Contract, usdt: Contract;
    let secret: Fr, secretHash: Fr;

    it('set owner and user', async () => {
        [ownerWallet, operatorWallet, userWallet] = await getSandboxAccountsWallets(pxe);
    });

    it('deploy contracts', async () => {
        bridge = await bridgeContract.deploy(ownerWallet, ownerWallet.getAddress(), ownerWallet.getAddress()).send().deployed();
        wmatic = await TokenContract.deploy(ownerWallet, ownerWallet.getAddress()).send().deployed();
        usdt = await TokenContract.deploy(ownerWallet, ownerWallet.getAddress()).send().deployed();
    });

    it('set operator and tokens, make bridge allowed to mint', async () => {
        await bridge.methods.set_operator(operatorWallet.getAddress()).send().wait();
        await bridge.methods.set_tokens(wmatic.address, usdt.address).send().wait();

        await wmatic.methods.set_minter(bridge.address, true).send().wait();
        await usdt.methods.set_minter(bridge.address, true).send().wait();
    });

    it('mint WMATIC to user\'s wallet privately', async () => {
        const secret = Fr.random();
        const secretHash = computeMessageSecretHash(secret);

        let receipt = await wmatic.methods.mint_private(100, secretHash).send().wait();

        const pendingShieldsStorageSlot = new Fr(5);
        const note = new Note([new Fr(100), secretHash]);
        await pxe.addNote(new ExtendedNote(note, userWallet.getAddress(), wmatic.address, pendingShieldsStorageSlot, receipt.txHash));

        wmatic = wmatic.withWallet(userWallet);

        await wmatic.methods.redeem_shield(userWallet.getAddress(), 100, secret).send().wait();

        const wmaticBalance = Number(await wmatic.methods.balance_of_private(userWallet.getAddress()).view());
        expect(wmaticBalance).toBe(100);
    });

    it('create a swap privately', async () => {
        wmatic = wmatic.withWallet(userWallet);
        bridge = bridge.withWallet(userWallet);

        secret = Fr.random();
        secretHash = computeMessageSecretHash(secret);

        const burnNonce = Fr.random();
        const burnMessageHash = computeAuthWitMessageHash(
            bridge.address,
            wmatic.methods.burn(userWallet.getAddress(), 5, burnNonce).request(),
        );
        const witness = await userWallet.createAuthWitness(burnMessageHash);
        await userWallet.addAuthWitness(witness);

        await bridge.methods.swap_private(1, wmatic.address, 2, 5, burnNonce, secretHash).send().wait();

        let userBalance = Number(await wmatic.methods.balance_of_private(userWallet.getAddress()).view());
        expect(userBalance).toBe(95);

        let swapData = await bridge.methods.get_swap(0).view();
        expect(Number(swapData.in_token_amount)).toBe(5);
        expect(Boolean(swapData.is_private)).toBe(true);
        expect(Boolean(swapData.is_executed)).toBe(false);
    });

    it('execute a private swap', async () => {
        bridge = bridge.withWallet(operatorWallet);

        let receipt = await bridge.methods.execute_swap_private(0, 10).send().wait();

        const pendingShieldsStorageSlot = new Fr(5);
        const note = new Note([new Fr(10), secretHash]);
        await pxe.addNote(new ExtendedNote(note, userWallet.getAddress(), usdt.address, pendingShieldsStorageSlot, receipt.txHash));

        await usdt.methods.redeem_shield(userWallet.getAddress(), 10, secret).send().wait();

        let userBalance = Number(await usdt.withWallet(userWallet).methods.balance_of_private(userWallet.getAddress()).view());
        expect(userBalance).toBe(10);

        let swapData = await bridge.methods.get_swap(0).view();
        expect(Number(swapData.out_token_amount)).toBe(10);
        expect(Boolean(swapData.is_executed)).toBe(true);
    });
});
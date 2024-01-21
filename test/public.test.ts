// @ts-ignore
import { TokenContract } from "@aztec/noir-contracts/Token";
import {
    AccountWalletWithPrivateKey, AztecAddress, computeAuthWitMessageHash,
    Contract,
    createPXEClient, Fr,
} from '@aztec/aztec.js';
// @ts-ignore
import { getInitialTestAccountsWallets } from "@aztec/accounts/testing";
import { bridgeContract } from "./fixtures/bridge";

const { PXE_URL = 'http://localhost:8080' } = process.env;


describe('deploy -> create pair -> swap', () => {
    const pxe = createPXEClient(PXE_URL);

    let ownerWallet: AccountWalletWithPrivateKey;
    let operatorWallet: AccountWalletWithPrivateKey;
    let userWallet: AccountWalletWithPrivateKey;
    let bridge: Contract, wmatic: Contract, usdt: Contract;

    it('set owner and user', async () => {
        [ownerWallet, operatorWallet, userWallet] = await getInitialTestAccountsWallets(pxe);
    });

    it('deploy contracts', async () => {
        bridge = await bridgeContract.deploy(ownerWallet, ownerWallet.getAddress()).send().deployed();
        wmatic = await TokenContract.deploy(ownerWallet, ownerWallet.getAddress(), "WMATIC", "WMATIC", 0).send().deployed();
        usdt = await TokenContract.deploy(ownerWallet, ownerWallet.getAddress(), "USDT", "USDT", 0).send().deployed();
    });

    it('set operator and tokens, make bridge allowed to mint', async () => {
        await bridge.methods.set_operator(operatorWallet.getAddress()).send().wait();
        await bridge.methods.set_tokens(wmatic.address, usdt.address).send().wait();

        await wmatic.methods.set_minter(bridge.address, true).send().wait();
        await usdt.methods.set_minter(bridge.address, true).send().wait();
    });

    it('mint WMATIC to user\'s wallet publicly', async () => {
        await wmatic.methods.mint_public(userWallet.getAddress(), 100).send().wait()
        const wmaticBalance = Number(await wmatic.methods.balance_of_public(userWallet.getAddress()).view());
        expect(wmaticBalance).toBe(100);
    });

    it('create a swap publicly', async () => {
        wmatic = wmatic.withWallet(userWallet);
        bridge = bridge.withWallet(userWallet);

        const burnNonce = Fr.random();
        const burnMessageHash = computeAuthWitMessageHash(
            bridge.address,
            wmatic.methods.burn_public(userWallet.getAddress(), 5, burnNonce).request(),
        );
        await userWallet.setPublicAuth(burnMessageHash, true).send().wait();
        await bridge.methods.swap_public(1, 2, 5, burnNonce).send().wait();

        let userBalance = Number(await wmatic.methods.balance_of_public(userWallet.getAddress()).view());
        expect(userBalance).toBe(95);

        let swapData = await bridge.methods.get_swap(0).view();
        expect(Number(swapData.in_token_amount)).toBe(5);
        expect(Boolean(swapData.is_executed)).toBe(false);
    });

    it('execute a public swap', async () => {
        bridge = bridge.withWallet(operatorWallet);

        await bridge.methods.execute_swap_public(0, 10).send().wait();

        let userBalance = Number(await usdt.methods.balance_of_public(userWallet.getAddress()).view());
        expect(userBalance).toBe(10);

        let swapData = await bridge.methods.get_swap(0).view();
        expect(Number(swapData.out_token_amount)).toBe(10);
        expect(Boolean(swapData.is_executed)).toBe(true);
    });
});
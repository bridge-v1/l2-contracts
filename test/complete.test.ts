import { TokenContract } from '@aztec/noir-contracts/types';
import {
    AccountWalletWithPrivateKey, AztecAddress, computeAuthWitMessageHash,
    Contract,
    createPXEClient, Fr,
    getSandboxAccountsWallets
} from '@aztec/aztec.js';
import { bridgeContract } from "./fixtures/bridge";

const { PXE_URL = 'http://localhost:8080' } = process.env;


async function approve(token: Contract, ownerWallet: AccountWalletWithPrivateKey, agent: AztecAddress, amount: Number) {
    const nonce = Fr.random();
    const transfer = token.methods.transfer_public(
        ownerWallet.getAddress(),
        agent,
        amount,
        nonce
    );
    const messageHash = await computeAuthWitMessageHash(agent, transfer.request());
    await ownerWallet.setPublicAuth(messageHash, true).send().wait();

    return nonce
}

describe('deploy -> create pair -> swap', () => {
    const pxe = createPXEClient(PXE_URL);

    let ownerWallet: AccountWalletWithPrivateKey;
    let operatorWallet: AccountWalletWithPrivateKey;
    let userWallet: AccountWalletWithPrivateKey;
    let bridge: Contract, wmatic: Contract, usdt: Contract;

    it('set owner and user', async () => {
        [ownerWallet, operatorWallet, userWallet] = await getSandboxAccountsWallets(pxe);
    });

    it('deploy contracts', async () => {
        bridge = await bridgeContract.deploy(ownerWallet, ownerWallet.getAddress(), ownerWallet.getAddress()).send().deployed();
        wmatic = await TokenContract.deploy(ownerWallet, ownerWallet.getAddress()).send().deployed();
        usdt = await TokenContract.deploy(ownerWallet, ownerWallet.getAddress()).send().deployed();
    });

    it('set operator', async () => {
        await bridge.methods.set_operator(operatorWallet.getAddress()).send().wait();
    });

    it('mint wmatic and usdt to owner', async () => {
        await wmatic.methods.mint_public(ownerWallet.getAddress(), 1000).send().wait()
        await usdt.methods.mint_public(ownerWallet.getAddress(), 500).send().wait()

        const wmaticBalance = Number(await wmatic.methods.balance_of_public(ownerWallet.getAddress()).view());
        const usdtBalance = Number(await usdt.methods.balance_of_public(ownerWallet.getAddress()).view());

        expect(wmaticBalance).toBe(1000);
        expect(usdtBalance).toBe(500);
    });

    it('generate token transfer proofs, top up the bridge', async () => {
        let wmaticBalance = Number(await wmatic.methods.balance_of_public(ownerWallet.getAddress()).view());
        let usdtBalance = Number(await usdt.methods.balance_of_public(ownerWallet.getAddress()).view());

        const wmaticNonce = await approve(wmatic, ownerWallet, bridge.address, wmaticBalance)
        const usdtNonce = await approve(usdt, ownerWallet, bridge.address, usdtBalance)

        await bridge.methods.add_token(
            1,
            wmatic.address,
            wmaticBalance,
            wmaticNonce
        ).send().wait();

        await bridge.methods.add_token(
            2,
            usdt.address,
            usdtBalance,
            usdtNonce
        ).send().wait();

        wmaticBalance = Number(await wmatic.methods.balance_of_public(ownerWallet.getAddress()).view());
        usdtBalance = Number(await usdt.methods.balance_of_public(ownerWallet.getAddress()).view());

        expect(wmaticBalance).toBe(0);
        expect(usdtBalance).toBe(0);

        wmaticBalance = Number(await wmatic.methods.balance_of_public(bridge.address).view());
        usdtBalance = Number(await usdt.methods.balance_of_public(bridge.address).view());

        expect(wmaticBalance).toBe(1000);
        expect(usdtBalance).toBe(500);
    });

    it('mint wmatic to user', async () => {
        await wmatic.methods.mint_public(userWallet.getAddress(), 5).send().wait()
        const wmaticBalance = Number(await wmatic.methods.balance_of_public(userWallet.getAddress()).view());
        expect(wmaticBalance).toBe(5);
    });

    it('create a public swap', async () => {
        wmatic = wmatic.withWallet(userWallet);
        bridge = bridge.withWallet(userWallet);

        let userBalance = Number(await wmatic.methods.balance_of_public(userWallet.getAddress()).view());
        const wmaticNonce = await approve(wmatic, userWallet, bridge.address, userBalance)

        await bridge.methods.swap_public(1, 5, wmaticNonce).send().wait();

        let bridgeBalance = Number(await wmatic.methods.balance_of_public(bridge.address).view());
        userBalance = Number(await wmatic.methods.balance_of_public(userWallet.getAddress()).view());
        expect(bridgeBalance).toBe(1005);
        expect(userBalance).toBe(0);

        let swapData = await bridge.methods.get_swap(0).view();
        expect(Number(swapData.amount)).toBe(5);
        expect(Boolean(swapData.executed)).toBe(false);
    });

    it('execute a public swap', async () => {
        bridge = bridge.withWallet(operatorWallet);

        await bridge.methods.execute_swap_public(0, 2, 10).send().wait();

        let bridgeBalance = Number(await usdt.methods.balance_of_public(bridge.address).view());
        expect(bridgeBalance).toBe(490);

        let userBalance = Number(await usdt.methods.balance_of_public(userWallet.getAddress()).view());
        expect(userBalance).toBe(10);

        let swapData = await bridge.methods.get_swap(0).view();
        expect(Boolean(swapData.executed)).toBe(true);
    });
});
import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types,
} from "https://deno.land/x/clarinet@v1.2.0/index.ts";
import { assertEquals } from "https://deno.land/std@0.90.0/testing/asserts.ts";

const mainContract = "clear-token";

Clarinet.test({
  name: "TEsting if get-symbol works correctly",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    let deployer = accounts.get("deployer")!;
    let wallet1 = accounts.get("wallet_1")!;
    let wallet2 = accounts.get("wallet_2")!;

    let symbol = chain.callReadOnlyFn(
      mainContract,
      "get-symbol",
      [],
      wallet1.address
    );
    symbol.result.expectOk().expectAscii("CLR");
  },
});

Clarinet.test({
  name: "Ensure that mint clear token is successfull and owner is the only one allowed to mint)",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    let deployer = accounts.get("deployer")!;
    let wallet1 = accounts.get("wallet_1")!;
    let wallet2 = accounts.get("wallet_2")!;

    let init_balance = chain.callReadOnlyFn(
      mainContract,
      "get-balance",
      [types.principal(deployer.address)],
      deployer.address
    );
    init_balance.result.expectOk().expectUint(0);

    let block = chain.mineBlock([
      // 1 - Minting for contract deployer and owner
      Tx.contractCall(
        mainContract,
        "mint",
        [types.uint(1000), types.principal(deployer.address)],
        deployer.address
      ),
      // 2 - Minting for other wallet address
      Tx.contractCall(
        mainContract,
        "mint",
        [types.uint(8), types.principal(wallet1.address)],
        deployer.address
      ),
      // 3 -Trying to mint as non deployer should result in error
      Tx.contractCall(
        mainContract,
        "mint",
        [types.uint(10000000), types.principal(wallet1.address)],
        wallet1.address
      ),
    ]);

    let end_balance = chain.callReadOnlyFn(
      mainContract,
      "get-balance",
      [types.principal(deployer.address)],
      deployer.address
    );
    end_balance.result.expectOk().expectUint(1000);
    let end_balance_wallet1 = chain.callReadOnlyFn(
      mainContract,
      "get-balance",
      [types.principal(wallet1.address)],
      deployer.address
    );
    end_balance_wallet1.result.expectOk().expectUint(8);
    block.receipts[2].result.expectErr().expectUint(100);

    let total_supply = chain.callReadOnlyFn(
      mainContract,
      "get-total-supply",
      [],
      deployer.address
    );
    total_supply.result.expectOk().expectUint(1000 + 8);
  },
});

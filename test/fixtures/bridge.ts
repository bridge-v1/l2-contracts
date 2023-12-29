
/* Autogenerated file, do not edit! */

/* eslint-disable */
import {
  AztecAddress,
  AztecAddressLike,
  CompleteAddress,
  Contract,
  ContractArtifact,
  ContractBase,
  ContractFunctionInteraction,
  ContractMethod,
  DeployMethod,
  EthAddress,
  EthAddressLike,
  FieldLike,
  Fr,
  Point,
  PublicKey,
  Wallet,
} from '@aztec/aztec.js';
import bridgeContractArtifactJson from '../../contracts/bridge/target/bridge.json' assert { type: 'json' };
export const bridgeContractArtifact = bridgeContractArtifactJson as ContractArtifact;

/**
 * Type-safe interface for contract bridge;
 */
export class bridgeContract extends ContractBase {
  
  private constructor(
    completeAddress: CompleteAddress,
    wallet: Wallet,
    portalContract = EthAddress.ZERO
  ) {
    super(completeAddress, bridgeContractArtifact, wallet, portalContract);
  }
  

  
  /**
   * Creates a contract instance.
   * @param address - The deployed contract's address.
   * @param wallet - The wallet to use when interacting with the contract.
   * @returns A promise that resolves to a new Contract instance.
   */
  public static async at(
    address: AztecAddress,
    wallet: Wallet,
  ) {
    return Contract.at(address, bridgeContract.artifact, wallet) as Promise<bridgeContract>;
  }

  
  /**
   * Creates a tx to deploy a new instance of this contract.
   */
  public static deploy(wallet: Wallet, owner: AztecAddressLike) {
    return new DeployMethod<bridgeContract>(Point.ZERO, wallet, bridgeContractArtifact, Array.from(arguments).slice(1));
  }

  /**
   * Creates a tx to deploy a new instance of this contract using the specified public key to derive the address.
   */
  public static deployWithPublicKey(publicKey: PublicKey, wallet: Wallet, owner: AztecAddressLike) {
    return new DeployMethod<bridgeContract>(publicKey, wallet, bridgeContractArtifact, Array.from(arguments).slice(2));
  }
  

  
  /**
   * Returns this contract's artifact.
   */
  public static get artifact(): ContractArtifact {
    return bridgeContractArtifact;
  }
  

  /** Type-safe wrappers for the public methods exposed by the contract. */
  public methods!: {
    
    /** _assert_operator(address: field) */
    _assert_operator: ((address: FieldLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** _assert_swap_params(swap_id: field, secret_hash_for_redeeming: field) */
    _assert_swap_params: ((swap_id: FieldLike, secret_hash_for_redeeming: FieldLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** _assert_token_is_same(in_token_id: field, in_token_address: field) */
    _assert_token_is_same: ((in_token_id: FieldLike, in_token_address: FieldLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** _initialize(owner: field) */
    _initialize: ((owner: FieldLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** _mint_private(out_token_address: field, amount: field, secret_hash: field) */
    _mint_private: ((out_token_address: FieldLike, amount: FieldLike, secret_hash: FieldLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** _save_swap(in_token_id: field, out_token_id: field, in_token_amount: field, l2_secret_hash: field) */
    _save_swap: ((in_token_id: FieldLike, out_token_id: FieldLike, in_token_amount: FieldLike, l2_secret_hash: FieldLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** _update_swap(swap_id: field, out_token_amount: field) */
    _update_swap: ((swap_id: FieldLike, out_token_amount: FieldLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** compute_note_hash_and_nullifier(contract_address: field, nonce: field, storage_slot: field, serialized_note: array) */
    compute_note_hash_and_nullifier: ((contract_address: FieldLike, nonce: FieldLike, storage_slot: FieldLike, serialized_note: FieldLike[]) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** execute_swap_private(swap_id: field, out_token_amount: field) */
    execute_swap_private: ((swap_id: FieldLike, out_token_amount: FieldLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** execute_swap_public(swap_id: field, out_token_amount: field) */
    execute_swap_public: ((swap_id: FieldLike, out_token_amount: FieldLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** get_counter() */
    get_counter: (() => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** get_storage() */
    get_storage: (() => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** get_swap(swap_id: field) */
    get_swap: ((swap_id: FieldLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** set_operator(operator: field) */
    set_operator: ((operator: FieldLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** set_tokens(token1: struct, token2: struct) */
    set_tokens: ((token1: AztecAddressLike, token2: AztecAddressLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** swap_private(in_token_id: field, in_token_address: field, out_token_id: field, in_token_amount: field, nonce_for_burn: field, secret_hash_for_redeeming: field) */
    swap_private: ((in_token_id: FieldLike, in_token_address: FieldLike, out_token_id: FieldLike, in_token_amount: FieldLike, nonce_for_burn: FieldLike, secret_hash_for_redeeming: FieldLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** swap_public(in_token_id: field, out_token_id: field, in_token_amount: field, nonce_for_burn: field) */
    swap_public: ((in_token_id: FieldLike, out_token_id: FieldLike, in_token_amount: FieldLike, nonce_for_burn: FieldLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;
  };
}

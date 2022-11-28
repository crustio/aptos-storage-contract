module crust_storage::storage {
    use std::signer;
    use std::vector;
    use std::string;
    use std::error;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::coin;
    use aptos_framework::account;
    use aptos_std::event;

    // Only owner has this resource
    struct OrderBasic has key {
        base_price: u64,
        byte_price: u64,
        size_limit: u64,
        service_price_rate: u64,
        nodes: vector<address>,
        order_events: event::EventHandle<OrderEvent>,
    }

    struct OrderEvent has drop, store {
        customer: address,
        merchant: address,
        cid: string::String,
        size: u64,
        price: u64,
    }

    const MODULE_OWNER: address = @0x59c6f5359735a27beba04252ae5fee4fc9c6ec0b7e22dab9f5ed7173283c54d0;

    const ENOT_INIT: u64 = 0;
    const ENOT_OWNER: u64 = 1;
    const ENODE_ALREADY_EXISTS: u64 = 2;
    const ENODE_NOT_FOUND: u64 = 3;
    const ESIZE_LIMIT_EXCEED: u64 = 4;
    const ENO_ENOUGH_BALANCE: u64 = 5;
    const ENO_ORDER_NODE: u64 = 6;

    public entry fun construct(owner: signer, base_price_: u64, byte_price_: u64, size_limit_: u64, service_price_rate_: u64) acquires OrderBasic {
        assert!(signer::address_of(&owner) == MODULE_OWNER, ENOT_OWNER);
        let owner_addr = signer::address_of(&owner);
        if (!exists<OrderBasic>(owner_addr)) {
            move_to(&owner, OrderBasic {
                base_price: base_price_,
                byte_price: byte_price_,
                size_limit: size_limit_,
                service_price_rate: service_price_rate_,
                nodes: vector::empty<address>(),
                order_events: account::new_event_handle<OrderEvent>(&owner),
            })
        } else {
            let order_basic = borrow_global_mut<OrderBasic>(owner_addr);
            order_basic.base_price = base_price_;
            order_basic.byte_price = byte_price_;
            order_basic.size_limit = size_limit_;
            order_basic.service_price_rate = service_price_rate_;
        }
    }

    public entry fun add_order_node(account: signer, node: address) acquires OrderBasic {
        let account_addr = signer::address_of(&account);
        assert!(exists<OrderBasic>(MODULE_OWNER), error::not_found(ENOT_INIT));
        assert!(account_addr == MODULE_OWNER, error::not_found(ENOT_OWNER));
        let order_basic = borrow_global_mut<OrderBasic>(account_addr);
        vector::push_back(&mut order_basic.nodes, node);
    }

    public entry fun remove_order_node(account: signer, node: address) acquires OrderBasic {
        let account_addr = signer::address_of(&account);
        assert!(exists<OrderBasic>(MODULE_OWNER), error::not_found(ENOT_INIT));
        assert!(account_addr == MODULE_OWNER, error::not_found(ENOT_OWNER));
        let order_basic = borrow_global_mut<OrderBasic>(account_addr);
        let (e, i) = vector::index_of<address>(&order_basic.nodes, &node);
        assert!(e, error::not_found(ENODE_NOT_FOUND));
        vector::remove<address>(&mut order_basic.nodes, i);
    }

    public entry fun set_order_price(account: signer, base_price_: u64, byte_price_: u64) acquires OrderBasic {
        let account_addr = signer::address_of(&account);
        assert!(exists<OrderBasic>(MODULE_OWNER), error::not_found(ENOT_INIT));
        assert!(account_addr == MODULE_OWNER, error::not_found(ENOT_OWNER));
        let order_basic = borrow_global_mut<OrderBasic>(account_addr);
        order_basic.base_price = base_price_;
        order_basic.byte_price = byte_price_;
    }

    public entry fun set_size_limit(account: signer, size_limit_: u64) acquires OrderBasic {
        let account_addr = signer::address_of(&account);
        assert!(exists<OrderBasic>(MODULE_OWNER), error::not_found(ENOT_INIT));
        assert!(account_addr == MODULE_OWNER, error::not_found(ENOT_OWNER));
        let order_basic = borrow_global_mut<OrderBasic>(account_addr);
        order_basic.size_limit = size_limit_;
    }

    public entry fun set_service_rate(account: signer, service_price_rate_: u64) acquires OrderBasic {
        let account_addr = signer::address_of(&account);
        assert!(exists<OrderBasic>(MODULE_OWNER), error::not_found(ENOT_INIT));
        assert!(account_addr == MODULE_OWNER, error::not_found(ENOT_OWNER));
        let order_basic = borrow_global_mut<OrderBasic>(account_addr);
        order_basic.service_price_rate = service_price_rate_;
    }

    public entry fun get_price(size: u64): u64 acquires OrderBasic {
        assert!(exists<OrderBasic>(MODULE_OWNER), error::not_found(ENOT_OWNER));
        let order_basic = borrow_global<OrderBasic>(MODULE_OWNER);
        assert!(size <= order_basic.size_limit, error::invalid_argument(ESIZE_LIMIT_EXCEED));
        (order_basic.base_price + size * order_basic.byte_price / (1024*1024)) * (order_basic.service_price_rate + 100) / 100
    }

    public entry fun place_order(customer: signer, cid: string::String, size: u64) acquires OrderBasic {
        let node = get_random_node(size);
        place_order_with_node(customer, cid, size, node)
    }

    public entry fun place_order_with_node(customer: signer, cid: string::String, size: u64, node: address) acquires OrderBasic {
        assert!(exists<OrderBasic>(MODULE_OWNER), error::not_found(ENOT_INIT));
        let order_basic = borrow_global_mut<OrderBasic>(MODULE_OWNER);
        assert!(size <= order_basic.size_limit, error::invalid_argument(ESIZE_LIMIT_EXCEED));

        let decimals = coin::decimals<AptosCoin>();
        let unit = 1 << decimals;
        let price = (order_basic.base_price + size * order_basic.byte_price / (1024*1024)) * (order_basic.service_price_rate + 100) / 100 / unit;
        assert!(coin::balance<AptosCoin>(signer::address_of(&customer)) >= price, error::invalid_argument(ENO_ENOUGH_BALANCE));
        coin::transfer<AptosCoin>(&customer, node, price);
        event::emit_event(&mut order_basic.order_events, OrderEvent {
            customer: signer::address_of(&customer),
            merchant: node,
            cid: cid,
            size: size,
            price: price,
        })
    }

    fun get_random_node(size: u64): address acquires OrderBasic {
        assert!(exists<OrderBasic>(MODULE_OWNER), error::not_found(ENOT_INIT));
        let order_basic = borrow_global<OrderBasic>(MODULE_OWNER);
        let nodes_num = vector::length(&order_basic.nodes);
        assert!(nodes_num > 0, error::not_found(ENO_ORDER_NODE));
        let node_index = size % nodes_num;
        *vector::borrow<address>(&order_basic.nodes, node_index)
    }
}

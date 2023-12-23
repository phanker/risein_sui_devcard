module devhub::devcard {
    use std::option::{Self, Option};
    use std::string::{Self, String};

    use sui::transfer;
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::url::{Self, Url};
    use sui::coin::{Self, Coin};
    use sui::object_table::{Self, ObjectTable};
    use sui::event;
    use std::vector;
    use sui::sui::SUI;

    const NOT_OWNER :u64 = 0;
    const INSUFFICIENT_FUNDS :u64 = 1;
    const MINT_CARD_COST :u64 = 2;


    struct DevCard has key ,store{
        id:UID,
        name:String,
        owner:address,
        title:String,
        img_url:Url,
        description:Option<String>,
        years_of_exp:u8,
        technoligies:String,
        protfolio:String,
        contact:String,
        open_to_work:bool,
    }

    struct DevHub has key{
        id:UID,
        owner:address,
        counter:u64,
        card:ObjectTable<u64,DevCard>,
    }

    //event
    struct CardCreated has copy,drop{
        id:ID,
        owner:address,
        name:String,
        title:String,
        contact:String,
    }

    struct DescriptionUpdated has copy,drop{
        owner:address,
        name:String,
        new_description:String,
    }

    
    struct ProtfolioUpdated has copy,drop{
        owner:address,
        name:String,
        new_protfolio:String,
    }

    fun init(ctx:&mut TxContext){
        let dev_hub = DevHub{
            id:object::new(ctx),
            owner:tx_context::sender(ctx),
            counter:0,
            card:object_table::new<u64,DevCard>(ctx),
        };
        transfer::share_object(dev_hub);
    }

    public entry fun create_card(name:vector<u8>,
            owner:address,
            title:vector<u8>,
            img_url:vector<u8>,
            description:vector<u8>,
            years_of_exp:u8,
            technoligies:vector<u8>,
            protfolio:vector<u8>,
            contact:vector<u8>,
            payment:Coin<SUI>,
            dev_hub:&mut DevHub,
            ctx:&mut TxContext
    ){
         assert!(coin::value(&payment) < MINT_CARD_COST,INSUFFICIENT_FUNDS);
         transfer::public_transfer(payment,tx_context::sender(ctx));
         
         let uid= object::new(ctx);
         let id = object::uid_to_inner(&uid);
         let description_option = option::none<String>();
         option::fill(&mut description_option,string::utf8(description));
         let devcard = DevCard {
                id:uid,
                name:string::utf8(name),
                owner,
                title:string::utf8(title),
                img_url:url::new_unsafe_from_bytes(img_url),
                description:description_option,
                years_of_exp,
                technoligies:string::utf8(technoligies),
                protfolio:string::utf8(protfolio),
                contact:string::utf8(contact),
                open_to_work:true,
            };
        dev_hub.counter = dev_hub.counter+1;
        object_table::add(&mut dev_hub.card,dev_hub.counter,devcard);

        let cardCreated = CardCreated{
                id,
                owner:tx_context::sender(ctx),
                name:string::utf8(name),
                title:string::utf8(title),
                contact:string::utf8(contact),
        };
        event::emit(cardCreated);
    }


    public entry fun update_card_description(devhub: &mut DevHub,id:u64,description: vector<u8>,ctx :&mut TxContext){
        let card = object_table::borrow_mut(&mut devhub.card,id);
        assert!(tx_context::sender(ctx) == devhub.owner,NOT_OWNER);
        option::swap_or_fill(&mut card.description,string::utf8(description));
        let descriptionUpdated = DescriptionUpdated{
            owner:tx_context::sender(ctx),
            name: card.name,
            new_description: string::utf8(description),
        };
        event::emit(descriptionUpdated);
    }


    public entry fun deactivate_card(devhub: &mut DevHub,id:u64,ctx :&mut TxContext){
        let card = object_table::borrow_mut(&mut devhub.card,id);
        assert!(tx_context::sender(ctx) == devhub.owner,NOT_OWNER);
        card.open_to_work = false;
    }

    public entry fun update_card_protfolio(devhub: &mut DevHub,id:u64,protfolio: vector<u8>,ctx :&mut TxContext){
        let card = object_table::borrow_mut(&mut devhub.card,id);
        assert!(tx_context::sender(ctx) == devhub.owner,NOT_OWNER);
        card.protfolio = string::utf8(protfolio);
        let protfolioUpdated = ProtfolioUpdated{
            owner:tx_context::sender(ctx),
            name: card.name,
            new_protfolio: string::utf8(protfolio),
        };
        event::emit(protfolioUpdated);
    }
}
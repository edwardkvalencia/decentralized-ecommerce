pragma solidity ^0.5.0;

import './ERC721.sol';

//E-commerce token that implements the ERC721 token with mint function
contract EcommerceToken is ERC721 {
    address public ecommerce;
    bool public isEcommerceSet = false;
    
    //generate new token for the specified address
    function mint(address _to, uint256 _tokenId) public {
        require(msg.sender == ecommerce, 'Only contract can mint new token');
        _mint(_to, _tokenId);
    }

    //Set ecommerce smart contract address
    function setEcommerce(address _ecommerce) public {
        require(!isEcommerceSet, 'Ecommerce address can only be set once');
        require(_ecommerce != address(0), 'Address cannot be empty');
        isEcommerceSet = true;
        ecommerce = _ecommerce;
    }
}

// Main ecommerce contract to buy and sell ERC-721 tokens
// Representing physical or digital products.
contract Ecommerce {
    struct Product {
        uint256 id;
        string title;
        string description;
        uint256 date;
        address payable owner;
        uint256 price;
        string image;
    }

    struct Order {
        uint256 id;
        string nameSurname;
        string lineOneDirection;
        string lineTwoDirection;
        bytes32 city;
        bytes32 stateRegion;
        uint256 postalCode;
        bytes32 country;
        uint256 phone;
        string state; //'pending'/'completed
    }

    //Seller address => products
    //Published products by the seller
    mapping(address => Product[]) public sellerProducts;
    // Products waiting to be fulfilled by the seller, used by
    //seller to check which orders have to be fulfilled
    mapping(address => Order[]) public pendingSellerOrders;

    // Buyer address => products
    // Products buyer purchased waiting to be sent
    mapping(address => Order[]) public pendingBuyerOrders;

    // Seller address => products
    // History of past orders fulfilled by the seller
    mapping(address => Order[]) public completedSellerOrders;

    // Buyer address => products
    // History of past orders made by buyer
    mapping(address => Order[]) public completedBuyerOrders;

    //Product Id => product
    mapping(uint256 => Product) public productById;

    // ProductId => Order
    mapping(uint256 => Order) public orderById;

    // Product id => true/false
    mapping(uint256 => bool) public productExists;

    Product[] public products;
    Order[] public orders;
    uint256 public lastId;
    address public token;
    uint256 public lastPendingSellerOrder;
    uint256 public lastPendingBuyerOrder;

    //To setup the address of the ERC721 token to use for this contract
    constructor(address _token) public {
        token = _token;
    }

    // To publish a product as a seller
    function publishProduct(
        string memory _title,
        string memory _description,
        uint256 _price,
        string memory _image
    ) public {
        require(bytes(_title).length > 0,'Title cannot be empty');
        require(bytes(_description).length > 0, 'description cannot be empty');
        require(_price > 0, 'price cannot be empty');
        require(bytes(_image).length > 0, 'Image cannot be empty');

        Product memory p = Product(
            lastId, 
            _title, 
            _description, 
            now, 
            msg.sender, 
            _price * 1e18, 
            _image
        );
        products.push(p);
        sellerProducts[msg.sender].push(p);
        productById[lastId] = p;
        productExists[lastId] = true;
        //Create new token for this product which will be owned
        // by the contract until sold
        EcommerceToken(token).mint(address(this), lastId);
        lastId++;
    }

    // To buy a product, seller must authorize contract
    // to manage the token
    function buyProduct(
        uint256 _id,
        string memory _nameSurname,
        string memory _lineOneDirection,
        string memory _lineTwoDirection,
        bytes32 _city,
        bytes32 _stateRegion,
        uint256 _postalCode,
        bytes32 _country,
        uint256 _phone
    ) public payable {
        // 2 line address and phone are optional
        require(productExists[_id], 'Product must exist to be purchased');
        require(bytes(_nameSurname).length > 0, 'Name and Surname must be set');
        require(bytes(_lineOneDirection).length > 0, 'Line one direction must be set');
        require(_city.length > 0, 'City must be set');
        require(_stateRegion.length > 0, 'State or region must be set');
        require(_postalCode > 0, 'Postal code must be set');
        require(_country > 0, 'Country must be set');

        Product memory p = productById[_id];

        Order memory newOrder = Order(
            _id, 
            _nameSurname,
            _lineOneDirection,
            _lineTwoDirection,
            _city,
            _stateRegion,
            _postalCode,
            _country,
            _phone,
            'pending'
        );
        require(msg.value >= p.price, 'Payment must be equal to or larger than price');

        // Return the excess ETH sent by the buyer
        if(msg.value > p.price) msg.sender.transfer(msg.value - p.price);
        
        pendingSellerOrders[p.owner].push(newOrder);
        pendingBuyerOrders[msg.sender].push(newOrder);
        orders.push(newOrder);
        orderById[_id] = newOrder;
        lastPendingSellerOrder = pendingSellerOrders[p.owner].length > 0 ? pendingSellerOrders[p.owner].length - 1 : 0;
        lastPendingBuyerOrder = pendingBuyerOrders[p.owner].length > 0 ? pendingBuyerOrders[p.owner].length - 1 : 0;

        //Transfer token to new owner
        EcommerceToken(token).transferFrom(p.owner, msg.sender, _id);
        p.owner.transfer(p.price);
    }

    //To mark an order completed
    function markOrderCompleted(uint256 _id) public {
        Order memory order = orderById[_id];
        Product memory product = productById[_id];
        require(product.owner == msg.sender, 'Only seller can mark order as completed');
        order.state = 'completed';

        // Delete seller order from the array of pending order
        for(uint256 i = 0; i < pendingSellerOrders[product.owner].length; i++) {
            if(pendingSellerOrders[product.owner][i].id == _id) {
                Order memory lastElement = orderById[lastPendingSellerOrder];
                pendingSellerOrders[product.owner][i] = lastElement;
                pendingSellerOrders[product.owner].length--;
                lastPendingSellerOrder--;
            }
        }

        // Delete the buyer order from the array of the pending orders
        for(uint256 i = 0; i < pendingBuyerOrders[msg.sender].length; i++) {
            if(pendingBuyerOrders[msg.sender][i].id == order.id) {
                Order memory lastElement = orderById[lastPendingBuyerOrder];
                pendingBuyerOrders[msg.sender][i] = lastElement;
                pendingBuyerOrders[msg.sender].length--;
                lastPendingBuyerOrder--;
            }
        }
        completedSellerOrders[product.owner].push(order);
        completedBuyerOrders[msg.sender].push(order);
        orderById[_id] = order;
    }

    // Get lastest product ids so that we can get each product independently
    function getLatestProductIds(uint256 _amount) public view returns(uint256[] memory) {
        //If more products requested than available, return available
        uint256 length = products.length;
        uint256 counter = (_amount > length) ? length : _amount;
        uint256 condition = (_amount > length) ? 0 : (length - _amount);
        uint256[] memory ids = new uint256[](_amount > length ? _amount : length);
        uint256 increment = 0;

        //Loop backwards to get the most recent products first
        for(int256 i = int256(counter); i >= int256(condition); i--) {
            ids[increment] = products[uint256(i)].id;
        }
        return ids;
    }

    // To get a single product broken down by properties
    function getProduct(uint256 _id) public view returns (
        uint256 id,
        string memory title,
        string memory description,
        uint256 date,
        address payable owner,
        uint256 price,
        string memory image
    ) {
        Product memory p = productById[_id];
        id = p.id;
        title = p.title;
        description = p.description;
        date = p.date;
        owner = p.owner;
        price = p.price;
        image = p.image;
    }

    // To get latest ids for a specific type of order
    function getLatestOrderIds(
        string memory _type, 
        address _owner, 
        uint256 _amount
    ) public view returns (uint256[] memory) {
        // If you're requesting more than available, return only available
        uint256 length;
        uint256 counter;
        uint256 condition;
        uint256[] memory ids;
        uint256 increment = 0;

        if(compareStrings(_type, 'pending-seller')) {
            length = pendingSellerOrders[_owner].length;
            counter = (_amount > length) ? length : _amount;
            condition = (_amount > length) ? 0 : (length - _amount);
            ids = new uint256[](_amount > length ? _amount : length);

            for(int256 i = int256(counter); i >= int256(condition); i--) {
                ids[increment] = uint256(pendingSellerOrders[_owner][uint256(i)].id);
            }
        } else if(compareStrings(_type, 'pending-buyer')) {
            length = pendingBuyerOrders[_owner].length;
            counter = (_amount > length) ? length : _amount;
            condition = (_amount > length) ? 0 : (length - _amount);
            ids = new uint256[](_amount > length ? _amount : length);

            for(int256 i = int256(counter); i >= int256(condition); i--) {
                ids[increment] = uint256(pendingBuyerOrders[_owner][uint256(i)].id);
            }
        } else if(compareStrings(_type, 'completed-seller')) {
            length = completedSellerOrders[_owner].length;
            counter = (_amount > length) ? length : _amount;
            condition = (_amount > length) ? 0 : (length - _amount);
            ids = new uint256[](_amount > length ? _amount : length);

            for(int256 i = int256(counter); i >= int256(condition); i--) {
                ids[increment] = uint256(completedSellerOrders[_owner][uint256(i)].id);
            }
        } else if(compareStrings(_type, 'completed-buyer')) {
            length = completedBuyerOrders[_owner].length;
            counter = (_amount > length) ? length : _amount;
            condition = (_amount > length) ? 0 : (length - _amount);
            ids = new uint256[](_amount > length ? _amount : length);

            for(int256 i = int256(counter); i >= int256(condition); i--) {
                ids[increment] = uint256(completedBuyerOrders[_owner][uint256(i)].id);
            }
        }

        return ids;
    }

    // To get individual orders with all parameters
    function getOrder(
        string memory _type, 
        address _owner, 
        uint256 _id
    ) public view returns(
        uint256 id,
        string memory nameSurname,
        string memory lineOneDirection,
        string memory lineTwoDirection,
        bytes32 city,
        bytes32 stateRegion,
        uint256 postalCode,
        bytes32 country,
        uint256 phone,
        string memory state
    ) {
        Order memory o;

        if(compareStrings(_type, 'pending-seller')) {
            o = pendingSellerOrders[_owner][_id];
        } else if (compareStrings(_type, 'pending-buyer')) {
            o = pendingBuyerOrders[_owner][_id];
        } else if (compareStrings(_type, 'completed-seller')) {
            o = completedSellerOrders[_owner][_id];
        } else if (compareStrings(_type, 'completed-buyer')) {
            o = completedBuyerOrders[_owner][_id];
        }

        id = o.id;
        nameSurname = o.nameSurname;
        lineOneDirection = o.lineOneDirection;
        lineTwoDirection = o.lineTwoDirection;
        city = o.city;
        stateRegion = o.stateRegion;
        postalCode = o.postalCode;
        country = o.country;
        phone = o.phone;
        state = o.state;
    }

    // To compare 2 strings since we can't use normal operator
    function compareStrings(string memory a, string memory b) public pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}
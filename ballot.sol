pragma solidity ^0.4.11;

contract FairAuction {
    
    struct Constructor {
        string name;
        uint bidPrice;
        uint riskAwareness;
    }
    
    struct Politician {
        string name;
        // the impression for every single constructor
        mapping(address => uint) impression;
        // the techQuality for every single constructor in opinion of politician
        mapping(address => uint) techQuality;
    }

    address public publicAngency;
    uint public biddingEnd;
    uint public revealEnd;
    bool public ended;

    mapping(address => Constructor) public constructors;
    address[] constructorsList;
    
    mapping(address => Politician) public politicians;
    address[] politiciansList;

    // map the constructor's address to performance in past
    mapping(address => uint) public performance;
    
    // map the constructor's address to impressions
    mapping(address => uint) public impressions;
    
    mapping(address => uint) public techQualities;
    
    // map the constructor's address to score
    mapping(address => uint) public scores;
    
    // map the constructor's address to its hash
    mapping(address => bytes32) public hashVals;

    address public bestConstructor;
    uint public bestScore;
    
    event AuctionEnded(string winner, uint highestBid);
    event ScoreCal(string constructor, uint best_Score);
    event BadBid(string constructor, bytes32 hashVal, bytes32 righHash);

    modifier onlyBefore(uint _time) { require(now < _time); _; }
    modifier onlyAfter(uint _time) { require(now > _time); _; }

    //function BlindAuction(uint _biddingTime, uint _revealTime, 
    //        address _publicAngency) public {
    function FairAuction() public payable {
        //if (_biddingTime == 0x0) _biddingTime = now + 5 minutes;
        //if (_revealTime == 0x0 ) _revealTime = _biddingTime + 30 seconds;
        //require(_publicAngency != 0x0);
        publicAngency = 0x1;
        biddingEnd = now + 2 minutes; // _biddingTime;
        revealEnd = biddingEnd + 30 seconds; // _revealTime;
    }

    //recieve hash
    function reciveHash(string _name, bytes32 _hashVal) public{
        constructors[msg.sender].name = _name;
        hashVals[msg.sender] = _hashVal;
    }
    
    function uintToString(uint v) public pure returns (string str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory s = new bytes(i);
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - 1 - j];
        }
        str = string(s);
    }

    // this function is for constructor to put a bid.
    function bid(string _name, uint _bidPrice) 
            public onlyBefore(biddingEnd) {
        var constructor = constructors[msg.sender];
        constructor.name = _name;
        constructor.bidPrice = _bidPrice;
        constructor.riskAwareness = 0;
        bytes32 hashVal = sha256(uintToString(_bidPrice));
        if(hashVals[msg.sender] != hashVal){
            BadBid(constructors[msg.sender].name, hashVal, hashVals[msg.sender]);
        }
        
        constructorsList.push(msg.sender);        
    }
    
    // this function let the politician to rate every constructor
    function rate(uint _techQuality, uint _impression, address _constructor) public {
        politicians[msg.sender].impression[_constructor] = _impression;
        politicians[msg.sender].techQuality[_constructor] = _techQuality;
    } 
    
    // this function evaluate all the constructors
    function evaluate (uint _price, uint _performance, uint _impression, 
            uint _techQuality, uint _riskAwareness) public returns(uint, address){
        uint best_Score = 10000000000;
        address best_Constructor;
        uint length = constructorsList.length;
        for (uint i = 0; i < length; i++) {
            uint score = constructors[constructorsList[i]].bidPrice * _price
                + constructors[constructorsList[i]].riskAwareness * _riskAwareness
                + performance[constructorsList[i]] * _performance
                + impressions[constructorsList[i]] * _impression 
                + techQualities[constructorsList[i]] * _techQuality;
            
            scores[constructorsList[i]] = score;
            if(best_Score > score) {
                best_Score = score;
                best_Constructor = constructorsList[i];
            }
        }
        
        ScoreCal(constructors[best_Constructor].name, constructors[best_Constructor].bidPrice);
        
        return (constructors[best_Constructor].bidPrice, best_Constructor);
        
    }



    /// End the auction and send the highest bid
    /// to the beneficiary.
    function auctionEnd() public onlyAfter(revealEnd) {
        require(!ended);
        AuctionEnded(constructors[bestConstructor].name, bestScore);
        ended = true;
        publicAngency.transfer(constructors[bestConstructor].bidPrice);
    }
}
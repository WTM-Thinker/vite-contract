pragma soliditypp ^0.4.2;
contract ViteBet{
    address owner;

    struct BetLimit {
        uint256 lowerLimit;
        uint256 upperLimit;
        uint256 tipPer;
    }

    tokenId[] tokens = ["tti_5649544520544f4b454e6e40"];
    mapping(tokenId => BetLimit) public tokenMap;

    event win(address indexed addr, uint256 rollTarget, uint256 betAmount, uint64 rollNum, uint256 winAmount);
    event lose(address indexed addr, uint256 rollTarget, uint256 betAmount, uint64 rollNum);
    event suspendBet(address indexed addr, uint256 rollTarget, uint256 betAmount);

    constructor() public {
        owner = msg.sender;
        tokenMap["tti_5649544520544f4b454e6e40"].lowerLimit = 1 vite;
        tokenMap["tti_5649544520544f4b454e6e40"].upperLimit = 100 vite;
        tokenMap["tti_5649544520544f4b454e6e40"].tipPer = 5;
    }

    onMessage () payable {
    }

    // Configure the upper and lower limits of the token bet
    // Configure the draw ratio (0 to 20)
    onMessage configBetLimit(uint256 ll, uint256 ul, uint256 tp) {
        require(owner == msg.sender);
        require(ll > 0 && ll <= ul);
        require(tp >= 0 && tp <= 20);
        if (tokenMap[msg.tokenid].lowerLimit == 0)
            tokens.push(msg.tokenid);
        tokenMap[msg.tokenid].lowerLimit = ll;
        tokenMap[msg.tokenid].upperLimit = ul;
        tokenMap[msg.tokenid].tipPer = tp;
    }

    onMessage DrawMoney(uint256 amount) {
        require(owner == msg.sender);
        require(amount <= balance(msg.tokenid));
        msg.sender.transfer(msg.tokenid, amount);
    }

    // Get the upper and lower limits of the token and the rate
    getter getBetLimit(tokenId token) returns(uint256 ll, uint256 ul, uint256 tipPer) {
        return (tokenMap[token].lowerLimit, tokenMap[token].upperLimit, tokenMap[token].tipPer);
    }

    // Get the token list
    getter getTokenList() returns(tokenId[] memory) {
        return tokens;
    }

    onMessage BetAndRoll(uint256 rollTargets) payable {
        uint256 betAmount = msg.amount;
        address betAddr = msg.sender;
        uint256 ll = tokenMap[msg.tokenid].lowerLimit;
        uint256 ul = tokenMap[msg.tokenid].upperLimit;
        require(ll > 0 && ll <= ul);
        require(betAmount >= ll && betAmount <= ul);
        require(rollTargets > 0 && rollTargets < 100000);

        uint64 randomNumber = random64();
        uint64 rollNum = randomNumber % 6 + 1;
        bool winBet = false;
        uint64 count = 0;
        uint256 tempRollTargets = rollTargets;
        while(tempRollTargets % 10 > 0) {
            count++;
            uint64 rollTarget = uint64(tempRollTargets % 10);
            require(rollTarget > 0 && rollTarget <= 6);
            if(rollTarget == rollNum) {
                winBet = true;
            }
            tempRollTargets = tempRollTargets / 10;
        }
        uint256 winAmount = calcWinAmount(betAmount, count, msg.tokenid);

        if(winBet == false) {
            // betAddr.transfer(msg.tokenId, 0);
            emit lose(betAddr, rollTargets, betAmount, rollNum);
        } else if(winBet == true && winAmount > balance(msg.tokenid)) {
            betAddr.transfer(msg.tokenid, betAmount);
            emit suspendBet(betAddr, rollTargets, betAmount);
        } else {
            betAddr.transfer(msg.tokenid, winAmount);
            emit win(betAddr, rollTargets, betAmount, rollNum, winAmount);
        }

    }

    function calcWinAmount(uint256 betAmount, uint256 length, tokenId token) public view returns(uint256) {
        uint256 bonus = betAmount * 6 / length;
        return betAmount + (bonus - betAmount) * (100 - tokenMap[token].tipPer) / 100;
    }

}

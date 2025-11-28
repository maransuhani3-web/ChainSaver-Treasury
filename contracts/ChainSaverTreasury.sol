default 24h delay

    struct WithdrawalRequest {
        address token;
        uint256 amount;
        uint256 releaseTime;
        bool executed;
    }

    mapping(address => bool) public authorizedAdmins;
    mapping(uint256 => WithdrawalRequest) public withdrawalRequests;
    uint256 public requestCount;

    event AdminAuthorized(address indexed admin);
    event AdminRevoked(address indexed admin);
    event Deposit(address indexed token, uint256 amount, address indexed sender);
    event WithdrawalRequested(uint256 indexed requestId, address indexed token, uint256 amount, uint256 releaseTime);
    event WithdrawalExecuted(uint256 indexed requestId, address indexed token, uint256 amount);
    event EmergencyWithdraw(address indexed token, uint256 amount, address indexed to);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyAdmin() {
        require(authorizedAdmins[msg.sender] || msg.sender == owner, "Not admin");
        _;
    }

    constructor() {
        owner = msg.sender;
        authorizedAdmins[msg.sender] = true;
    }

    ADMIN MANAGEMENT
    ------------------------------------------------
    ------------------------------------------------
    function deposit(address token, uint256 amount) external {
        require(amount > 0, "Zero deposit");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        emit Deposit(token, amount, msg.sender);
    }

    WITHDRAWAL WITH TIME LOCK
    ------------------------------------------------
    ------------------------------------------------
    function emergencyWithdraw(address token, uint256 amount, address to) external onlyOwner {
        require(amount <= IERC20(token).balanceOf(address(this)), "Insufficient balance");
        IERC20(token).transfer(to, amount);
        emit EmergencyWithdraw(token, amount, to);
    }

    VIEW UTILITIES
    // ------------------------------------------------
    function pendingWithdrawal(uint256 requestId) external view returns (uint256, uint256, bool) {
        WithdrawalRequest storage req = withdrawalRequests[requestId];
        return (req.amount, req.releaseTime, req.executed);
    }

    function isAdmin(address user) external view returns (bool) {
        return authorizedAdmins[user];
    }

    function setWithdrawalDelay(uint256 delaySeconds) external onlyOwner {
        withdrawalDelay = delaySeconds;
    }
}
// 
Contract End
// 

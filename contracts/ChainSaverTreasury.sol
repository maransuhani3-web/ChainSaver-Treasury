State variables
    address public owner;
    uint256 public totalDeposits;
    uint256 public totalWithdrawals;
    uint256 public savingsGoal;
    bool public emergencyMode;
    
    Mappings
    mapping(address => Deposit[]) public userDeposits;
    mapping(address => uint256) public userBalances;
    mapping(address => Beneficiary) public beneficiaries;
    
    Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier notInEmergencyMode() {
        require(!emergencyMode, "Contract is in emergency mode");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        emergencyMode = false;
    }
    
    /**
     * @dev Function 1: Deposit funds into treasury
     */
    function deposit() external payable notInEmergencyMode {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        userDeposits[msg.sender].push(Deposit({
            amount: msg.value,
            timestamp: block.timestamp,
            isActive: true
        }));
        
        userBalances[msg.sender] += msg.value;
        totalDeposits += msg.value;
        
        emit DepositMade(msg.sender, msg.value, block.timestamp);
    }
    
    /**
     * @dev Function 2: Withdraw funds from treasury
     */
    function withdraw(uint256 _amount) external notInEmergencyMode {
        require(userBalances[msg.sender] >= _amount, "Insufficient balance");
        require(_amount > 0, "Withdrawal amount must be greater than 0");
        
        userBalances[msg.sender] -= _amount;
        totalWithdrawals += _amount;
        
        payable(msg.sender).transfer(_amount);
        
        emit WithdrawalMade(msg.sender, _amount, block.timestamp);
    }
    
    /**
     * @dev Function 3: Set savings goal
     */
    function setSavingsGoal(uint256 _goal) external onlyOwner {
        require(_goal > 0, "Goal must be greater than 0");
        savingsGoal = _goal;
        
        emit SavingsGoalSet(_goal);
    }
    
    /**
     * @dev Function 4: Add beneficiary with allowance
     */
    function addBeneficiary(address _beneficiary, uint256 _allowance) external onlyOwner {
        require(_beneficiary != address(0), "Invalid beneficiary address");
        require(_allowance > 0, "Allowance must be greater than 0");
        
        beneficiaries[_beneficiary] = Beneficiary({
            beneficiaryAddress: _beneficiary,
            allowance: _allowance,
            isActive: true
        });
        
        emit BeneficiaryAdded(_beneficiary, _allowance);
    }
    
    /**
     * @dev Function 5: Remove beneficiary
     */
    function removeBeneficiary(address _beneficiary) external onlyOwner {
        require(beneficiaries[_beneficiary].isActive, "Beneficiary not active");
        
        beneficiaries[_beneficiary].isActive = false;
        
        emit BeneficiaryRemoved(_beneficiary);
    }
    
    /**
     * @dev Function 6: Allocate funds to beneficiary
     */
    function allocateFunds(address _beneficiary, uint256 _amount) external onlyOwner notInEmergencyMode {
        require(beneficiaries[_beneficiary].isActive, "Beneficiary not active");
        require(_amount <= beneficiaries[_beneficiary].allowance, "Amount exceeds allowance");
        require(address(this).balance >= _amount, "Insufficient contract balance");
        
        beneficiaries[_beneficiary].allowance -= _amount;
        payable(_beneficiary).transfer(_amount);
        
        emit FundsAllocated(_beneficiary, _amount);
    }
    
    /**
     * @dev Function 7: Get user balance
     */
    function getUserBalance(address _user) external view returns (uint256) {
        return userBalances[_user];
    }
    
    /**
     * @dev Function 8: Get total contract balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Function 9: Toggle emergency mode
     */
    function toggleEmergencyMode() external onlyOwner {
        emergencyMode = !emergencyMode;
        
        emit EmergencyModeToggled(emergencyMode);
    }
    
    /**
     * @dev Function 10: Get user deposit history
     */
    function getUserDepositHistory(address _user) external view returns (Deposit[] memory) {
        return userDeposits[_user];
    }
    
    /**
     * @dev Check if savings goal is reached
     */
    function isSavingsGoalReached() external view returns (bool) {
        return address(this).balance >= savingsGoal;
    }
    
    /**
     * @dev Emergency withdrawal (only owner, only in emergency mode)
     */
    function emergencyWithdraw() external onlyOwner {
        require(emergencyMode, "Emergency mode not active");
        
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
    }
    
    End
End
// 
// 
End
// 

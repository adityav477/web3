// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract CharityDonation {
    /* Errors */
    error CharityDonation__NotOwner();
    error CharityDonation__InvalidDonorAddress();
    error CharityDonation__AmountCannotBeZero();
    error CharityDonation__InvalidOrganizationId();
    error CharityDonation__InvalidDonorId();
    error CharityDonation__OnlyOrganizationOwnerCanWithrdaw();
    error CharityDonation__AmountGreaterThanDonation();
    error CharityDonation__WithdrawalFailed();

    /* Events */
    event CharityDonation_OrganizationCreated(
        string indexed name,
        address indexed ownerOrganization,
        uint256 indexed timeStamp
    );

    event CharityDonation_donorAdded(address indexed newDonor);

    event CharityDonation_Donated(
        address indexed donor,
        address indexed organization,
        uint256 indexed amount
    );

    event CharityDonation_FundsWithdrawn(address owner, uint256 amount);

    /* Struct */
    struct NewOrganization {
        string name;
        address owner;
        uint256 timeStamp;
        Donation[] donations;
        Withdrawal[] withdrawals;
    }

    struct Donor {
        address donorAddress;
        uint256 totalDonated;
        uint256[] donationAmounts;
        uint256[] donationTimestamps;
    }

    struct Donation {
        address donor;
        uint256 amount;
        string message;
        uint256 timestamp;
    }

    struct Withdrawal {
        uint256 organizationId;
        uint256 timeStamp;
        string purpose;
    }

    /* State Variables */
    mapping(uint256 organizationId => NewOrganization newOrganization) s_idToOrganization;
    uint256 private s_organizationsCount;

    address private immutable i_owner;

    mapping(uint256 donorId => Donor newDonor) s_idToDonor;
    uint256 private s_donorsLength;

    mapping(address donor => mapping(uint256 organizationId => uint256 amount))
        private s_donorToOrganizationAmount;

    constructor() {
        i_owner = msg.sender;
        s_organizationsCount = 0;
        s_donorsLength = 0;
    }

    /* Modifier */
    modifier isOwner() {
        if (msg.sender != i_owner) {
            revert CharityDonation__NotOwner();
        }
        _;
    }

    modifier isOrganizationOwner(uint256 organizationId) {
        if (organizationId < 0 || organizationId > s_organizationsCount) {
            revert CharityDonation__InvalidOrganizationId();
        }
        if (msg.sender != s_idToOrganization[organizationId].owner) {
            revert CharityDonation__OnlyOrganizationOwnerCanWithrdaw();
        }
        _;
    }

    function addOrganization(
        string memory contractName,
        address organizationOwner
    ) external isOwner {
        // Donation[] memory emptyArrayDonation;
        // Withdrawal[] memory emptyArrayWithdrawal;

        NewOrganization memory newOrganization = s_idToOrganization[
            s_organizationsCount
        ];

        newOrganization.name = contractName;
        newOrganization.owner = organizationOwner;
        newOrganization.timeStamp = block.timestamp;

        // s_idToOrganization[s_organizationsCount] = newOrganization;
        s_organizationsCount++;

        emit CharityDonation_OrganizationCreated(
            contractName,
            organizationOwner,
            block.timestamp
        );
    }

    function addDonor(address donorAddress) external {
        if (donorAddress == address(0)) {
            revert CharityDonation__InvalidDonorAddress();
        }

        uint256[] memory emptyArrayUint;

        s_idToDonor[s_donorsLength] = Donor(
            donorAddress,
            0,
            emptyArrayUint,
            emptyArrayUint
        );
        s_donorsLength++;

        emit CharityDonation_donorAdded(donorAddress);
    }

    function donate(uint256 donorId, uint256 organizationId) external payable {
        if (msg.value <= 0) {
            revert CharityDonation__AmountCannotBeZero();
        }

        if (organizationId < 0 || organizationId > s_organizationsCount) {
            revert CharityDonation__InvalidOrganizationId();
        }

        if (donorId < 0 || donorId > s_donorsLength) {
            revert CharityDonation__InvalidDonorId();
        }

        s_donorToOrganizationAmount[msg.sender][organizationId] += msg.value;
        s_idToDonor[donorId].donationAmounts.push(msg.value);
        s_idToDonor[donorId].totalDonated += msg.value;
        s_idToDonor[donorId].donationTimestamps.push(block.timestamp);

        emit CharityDonation_Donated(
            s_idToDonor[donorId].donorAddress,
            s_idToOrganization[organizationId].owner,
            msg.value
        );
    }

    function withdraw(
        uint256 organizationId,
        uint256 amount
    ) external payable isOrganizationOwner(organizationId) {
        if (amount > address(this).balance) {
            revert CharityDonation__AmountGreaterThanDonation();
        }

        (bool success, ) = payable(msg.sender).call{value: amount}("");

        if (!success) {
            revert CharityDonation__WithdrawalFailed();
        } else {
            emit CharityDonation_FundsWithdrawn(msg.sender, amount);
        }
    }

    //Getter functions
    function getOwner() external view returns (address owner) {
        return i_owner;
    }

    function getOrganizationOwnerByOrganizationId(
        uint256 organizationId
    )
        external
        view
        isOrganizationOwner(organizationId)
        returns (address owner)
    {
        return s_idToOrganization[organizationId].owner;
    }

    // function getTotalDonationById( )
}

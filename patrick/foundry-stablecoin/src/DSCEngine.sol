// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/* @title DSCE
 *  @dev Me
 *  @description - this is the system which will be the backbone of our DSCStable coin
 *  DSCE will manage all the calculations which linclude
 *  1. User token Balance < Collateral Balance
 *  2. Allows Liquidation of the tokens by any user
 *  3. Minting of the tokens
 *  4. Burning of the tokens
 *  5. Only Certain Collaterals are only allowed which were determined during the deployment
 *  6. The 1 token needs to be equal to 1 dollar for which we will use priceFeeds by chainlink
 &  7. Buffer between the collateral and the DSC minted by a user - suppose  a use had $ 100 eth as collateral and minted $ 50 DSC 
       now the value of the eth changes and $100 eth now reaches $74 ETH and our buffe was 100 dollar worth DSc minted -> 150 dollar worth collateral
       thus once the collateral worth of eth falls to $74 from $ 100 then the buffer is not more satisfied thus we allow any other user to get 
       liquidate the users collateral by burning the $50 worth of DSC and get the $74 worth of ETH and make the profit of $24 
       this happens only if at the current time the original minter doesn't have enough DSc to mint and maintain the uffer 
       this will also happen if the user do not want to invest more eth 
 *
 *
 */

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {DSC} from "../src/DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {console} from "forge-std/Test.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract DSCE is ReentrancyGuard {
    /* Error */
    error DSCE__NotEnoughAmount();
    error DSCE__collateralTokensNotMatchPriceFeedAddresses();
    error DSCE__dscAddressNotValid();
    error DSCE__UserAddressNotValid();
    error DSCE__TokenAddressInvalid();
    error DSCE__TransferFailed();
    error DSCE__ZeroCollateralDeposited();
    error DSCE__ThreshholdCollateralNotMaintained();
    error DSCE__MintingFailed();
    error DSCE__CollateralAmountGreaterThanBalance();
    error DSCE__RedeemCollateralFailed();
    error DSCE__NotEnoughDSC();
    error DSCE__DSCTransferForBurningFailed();
    error DSCE__HealthFactorofUserIsFine();
    error DSCE__NotEnoughCollateralForLiquidation();
    error DSCE__HealthFactorNotImproved();

    /* Events */
    event DSCE_CollateralDeposited(
        address indexed depositer,
        address indexed tokenDepositedAddress,
        uint256 indexed amountDeposited
    );

    event DSCE_CollateralRedeemed(
        address from,
        address to,
        address tokenAddress,
        uint256 value
    );
    event DSCE_MintedDSC(address minter, uint256 amountMinted);
    event DSCE_dscBurned(address burner, uint256 amountBurned);

    /* State Variables */
    mapping(address token => address priceFeedAddress)
        private s_tokentoPriceFeedAddress;

    mapping(address user => mapping(address tokenCollateral => uint256 amount))
        private s_amountofTokenForUser;

    mapping(address user => uint256 amountMinted) public s_DSCMinted;
    address[] public s_acceptedTokenAddresses;

    /* Constants */
    uint256 private constant TEN_ZEROES = 1e10;
    uint256 private constant EIGHTEEN_ZEROES = 1e18;

    uint256 private constant THRESHOLD_DSC_WRT_COLLATERAL = 70 * 1e18; //if 100 $ is collateral then 70% should be the Max DSC Minted
    // that is if 100 $ worth of DSC is Minted then the $ 142.85  of Collateral should be maintained

    // To store the qamount of DSC minted by a user

    /* immutable variables */
    DSC immutable i_dsc;

    /* Modifiers */
    modifier notEnoughAmount(uint256 amount) {
        if (amount <= 0) {
            revert DSCE__NotEnoughAmount();
        }
        _;
    }

    modifier isValidToken(address token) {
        if (token == address(0)) {
            revert DSCE__TokenAddressInvalid();
        }

        if (s_tokentoPriceFeedAddress[token] == address(0)) {
            revert DSCE__TokenAddressInvalid();
        }
        _;
    }

    modifier isValidAddress(address userAddress) {
        if (userAddress == address(0)) {
            revert DSCE__UserAddressNotValid();
        }
        _;
    }

    /* Functions */
    constructor(
        address[] memory collateralTokenAddresses,
        address[] memory priceFeedAddressesofTokens,
        address dscAddress
    ) {
        if (
            collateralTokenAddresses.length != priceFeedAddressesofTokens.length
        ) {
            revert DSCE__collateralTokensNotMatchPriceFeedAddresses();
        }

        if (dscAddress == address(0)) {
            revert DSCE__dscAddressNotValid();
        }

        i_dsc = DSC(dscAddress);

        uint256 lenghtOfArray = collateralTokenAddresses.length;
        for (uint256 i = 0; i < lenghtOfArray; i++) {
            s_tokentoPriceFeedAddress[
                collateralTokenAddresses[i]
            ] = priceFeedAddressesofTokens[i];

            s_acceptedTokenAddresses.push(collateralTokenAddresses[i]);
        }
    }

    /* External Functions */

    /*
     * @params token amount- amount of token allowd to give as collateral
     * @params =tokenAddress - address of the token to deposited as collateral (in wei if eth)
     */
    function depositCollateral(
        uint256 _amount,
        address tokenAddress
    ) public notEnoughAmount(_amount) isValidToken(tokenAddress) nonReentrant {
        s_amountofTokenForUser[msg.sender][tokenAddress] += _amount;
        emit DSCE_CollateralDeposited(msg.sender, tokenAddress, _amount);
        bool success = IERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        // console.log("success is ",success);
        // console.log("in collateral the minted is ",s_amountofTokenForUser[msg.sender][tokenAddress]);
        // console.log("msg.sender is ",msg.sender);

        if (!success) {
            revert DSCE__TransferFailed();
        }
    }

    /*
     * NOTE: deposits and mints the dsc if the buffer is maintained
     */
    function depositCollateralAndMintDSC(
        uint256 _amountofCollateral,
        address tokenCollateralAddress,
        uint256 _amountofDSCToMint
    ) external {
        depositCollateral(_amountofCollateral, tokenCollateralAddress);
        mintDSC(_amountofDSCToMint);
    }

    /*
     * @params tokenCollateralAddress - the collateral to withdraw
     * @params amountofCollateral - the amount of collaterl to be redeem for givem tokenCollateral
     * @params amountOfDSC - amount of DSC to be burned
     */
    function redeemCollateralAndBurnDSC(
        address tokenCollateralAddress,
        uint256 amountOfCollateral,
        uint256 amountOfDSC
    ) external {
        burnDSC(amountOfDSC);
        // console.log("done with burndsc");
        redeemCollateral(tokenCollateralAddress, amountOfCollateral);
    }

    function redeemCollateral(
        address tokenCollateralAddress,
        uint256 amount
    ) public notEnoughAmount(amount) isValidToken(tokenCollateralAddress) {
        _redeemCollateral(
            tokenCollateralAddress,
            amount,
            msg.sender,
            msg.sender
        );
        _revertIfHealthFactorFails(msg.sender);
    }

    /*
     * NOTE: Needs to check if the buffer of amount of DSC Minted and the Value of Collateral in total is maintained
     */
    function mintDSC(
        uint256 amountToBeMinted
    ) public notEnoughAmount(amountToBeMinted) {
        s_DSCMinted[msg.sender] += amountToBeMinted;

        //rever if the buffer is notmaintained between the value of collateral tokens and DSC Minted
        _revertIfHealthFactorFails(msg.sender);

        bool success = i_dsc.mint(msg.sender, amountToBeMinted);

        // console.log("i_dsc.balanceOf[user] is ",i_dsc.balanceOf(msg.sender));

        if (!success) {
            revert DSCE__MintingFailed();
        }

        emit DSCE_MintedDSC(msg.sender, amountToBeMinted);
    }

    function burnDSC(
        uint256 amountToBurn
    ) public notEnoughAmount(amountToBurn) {
        // console.log("msg.sender is ",msg.sender);
        // console.log("i_dsc balance in engine is ",i_dsc.balanceOf(msg.sender));
        _burnDSC(amountToBurn, msg.sender, msg.sender);

        //even though the user is burning the coin we don't know if that is enough for the user to get the healthfactor correct again
        //thus we need to revert if the user burning doesn't maintains the healthfactor even after burning coin
        //but then comes the point what if the user wants to get some of its collateral back as much as he can from the previous collateral
        //then we must provide him that
        // but since the user gets back to the liquidation as soon as he losses to maintain the buffer than there is no need for partial burning
        // but burndsc is for him to before hitting the liquidation point thus this will never hit the _revertIfHealthFactorFails
        _revertIfHealthFactorFails(msg.sender);
        emit DSCE_dscBurned(msg.sender, amountToBurn);
    }

    function liquidate(
        address tokenCollateralAddress,
        address userToBeLiquidated,
        uint256 amountToBeFreed
    ) external {
        //reverts if the user is health that is the amount of its caollateral in dollars is greater than
        if (_healthFactor(userToBeLiquidated) <= THRESHOLD_DSC_WRT_COLLATERAL) {
            revert DSCE__HealthFactorofUserIsFine();
        }
        uint256 startHealthFactor = getHealthFactor(userToBeLiquidated);

        /*TODO: give the auction logic and the highest bid/collateral ratio wins and only calls this function liquidate */

        /*
         * NOTE: we want to give the 10% bonus to the liquidator on the amount of Dsc they minted so for $100 dsc we give $110 of collateral here ETH
         */
        uint256 finalAmountUsd = amountToBeFreed + (amountToBeFreed * 10) / 100; // 0.1 that is 10 percent of original collateral in usd
        uint256 tokenEquivalentToAmount = getTokenEquivalentToAmount(
            tokenCollateralAddress,
            finalAmountUsd
        );
        console.log("tokenEquivalentToAmount is ", tokenEquivalentToAmount);

        _redeemCollateral(
            tokenCollateralAddress,
            tokenEquivalentToAmount,
            userToBeLiquidated,
            msg.sender
        );
        console.log("collateral redeemed in liquidate");
        _burnDSC(amountToBeFreed, msg.sender, userToBeLiquidated);

        //check if the users helathfactors increases or not after liquidation
        uint256 afterHealthFactor = getHealthFactor(userToBeLiquidated);
        if (startHealthFactor <= afterHealthFactor) {
            revert DSCE__HealthFactorNotImproved();
        }

        // the liquidators healthfactor will not change since he is giving the dsc for burning to liquidation user so it doesn't affects his dsc/collateral in valuls ration
        // so i guess there is not need to check th ehealth factor of the liquidator
        // but if the liquidator is minting the new dsc and giving them for burning than it may create a problem so checking is important of the healtfactor of liquidator
        _revertIfHealthFactorFails(msg.sender);
    }

    function getTokenEquivalentToAmount(
        address tokenCollateralAddress,
        uint256 amountInUsd
    ) public view returns (uint256 tokenEquivalent) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            s_tokentoPriceFeedAddress[tokenCollateralAddress]
        );

        (, int256 answer, , , ) = priceFeed.latestRoundData();

        // now we get the amountInusd in normal form thus we need to use the math accordingly and not in 10e18 form
        // here if for 2 eth we get 2000 in usd than we first equate the amountInsusd with 1e8 since anser is in factor of 1e8 and than convert the final
        // equivalent to wei rather than eth
        // console.log("answer is ",answer); // 2000,00,000,000
        // console.log("amountInUsd is ",amountInUsd);
        tokenEquivalent = ((amountInUsd * 1e8) / uint256(answer)) * 1e18;
    }

    /*NOTE:
     * calculates the collateral value based on the user address by running the for loop
     * through all the collateral tokens address and gets the sum of the amount of all the tokens
     */

    function getTotalCollateralValueForUserInUsd(
        address user
    ) public view returns (uint256 totalCollateralValue) {
        uint256 length = s_acceptedTokenAddresses.length;
        // console.log("user in getTotalCollateralValueForUserInUsd is ",user);
        for (uint256 i = 0; i < length; i++) {
            address token = s_acceptedTokenAddresses[i];
            uint256 amount = s_amountofTokenForUser[user][token];
            // console.log("amount is ",amount);
            totalCollateralValue += getUsdValue(token, amount);
            // console.log("totalCollateralValue is, ",totalCollateralValue);
        }
        // console.log("totalCollateralValue is ",totalCollateralValue);
        return totalCollateralValue;
    }

    //1,000,000,000,000,000,000,000

    /*NOTE:
     * gets the value of token based on the token address and the usd value of the amount of that token by
     * using the chainlink Data feeds
     */
    function getUsdValue(
        address token,
        uint256 amount // this is in wei
    ) public view returns (uint256 convertedValueInUsd) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            s_tokentoPriceFeedAddress[token]
        );

        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // console.log("answer is ",answer);

        //the amount in usd is with amount * 1e18 because the amount of collateral is in wei i.e, * e18
        //NOTE: WE do thhe numbers in e18 because solidity doesn't has floating numbers thus we need to maintain the precision of values we use e18 numbers
        convertedValueInUsd =
            ((uint256(answer) * TEN_ZEROES) * amount) /
            (EIGHTEEN_ZEROES * EIGHTEEN_ZEROES);
    }

    ////////////////////////
    /* INTERNAL fUNCTIONS */
    ////////////////////////

    function _redeemCollateral(
        address tokenAddress,
        uint256 tokenValue,
        address fromUser,
        address toUser
    ) internal {
        if (tokenValue > s_amountofTokenForUser[fromUser][tokenAddress]) {
            console.log("tokenValue is ", tokenValue);
            console.log(
                "s_amountotoken for user is ",
                s_amountofTokenForUser[fromUser][tokenAddress]
            );
            revert DSCE__CollateralAmountGreaterThanBalance();
        }
        s_amountofTokenForUser[fromUser][tokenAddress] -= tokenValue;

        //Now we need to check if the health factor gets below the requried buffer then we revert the error
        bool success = IERC20(tokenAddress).transfer(toUser, tokenValue);
        if (!success) {
            revert DSCE__RedeemCollateralFailed();
        }

        emit DSCE_CollateralRedeemed(
            fromUser,
            toUser,
            tokenAddress,
            tokenValue
        );
    }

    function _burnDSC(
        uint256 amountToBeBurned,
        address from,
        address forUser
    )
        internal
        notEnoughAmount(amountToBeBurned)
        isValidAddress(from)
        isValidAddress(forUser)
    {
        //TODO: need to add logic so that if the amounttobeburned is greater than s_DSCMinted[forUser] then we need to store the extra dsc for emergency

        if (amountToBeBurned > s_DSCMinted[from]) {
            revert DSCE__NotEnoughDSC();
        }

        // console.log("s_DScMinted[from] is ",s_DSCMinted[from]);
        s_DSCMinted[forUser] -= amountToBeBurned;
        // console.log("from is ",from);
        // console.log("forUser is ",forUser);
        // console.log("msg.sender in _burnDSCIs ",msg.sender);

        bool success = i_dsc.transferFrom(
            from,
            address(this),
            amountToBeBurned
        );

        if (!success) {
            revert DSCE__DSCTransferForBurningFailed();
        }

        i_dsc.burn(amountToBeBurned);
    }

    /*NOTE:
     * compares the value of the amount of collateral deposited by user and the amount of DSC Minted by user
     * */
    function _healthFactor(address user) internal view returns (uint256) {
        uint256 totalMintedDSCValue = s_DSCMinted[user];
        uint256 totalCollateralDepositedValue = getTotalCollateralValueForUserInUsd(
                user
            );

        if (totalCollateralDepositedValue == 0) {
            revert DSCE__ZeroCollateralDeposited();
        }
        console.log("totalMintedDSCValue is ", totalMintedDSCValue);
        console.log(
            "totalCollateralDepositedValue is ",
            totalCollateralDepositedValue
        );

        uint256 percentageOfDSCwrtCollateral = ((totalMintedDSCValue * 1e18) /
            totalCollateralDepositedValue) * 100;
        console.log(
            "percentageOfDSCwrtCollateral is ",
            percentageOfDSCwrtCollateral
        );
        return percentageOfDSCwrtCollateral;
    }

    /* NOTE:
     * 1. Checks the health that is the buffer is maintained between the total collateral and the amount of DSC Minted by user
     *  this will be done by comparing the amounts of DSCMinted and the total Collateral Deposited by the user
     */
    function _revertIfHealthFactorFails(address user) internal view {
        uint256 percentageOfDSCwrtCollateral = _healthFactor(user);
        if (percentageOfDSCwrtCollateral > THRESHOLD_DSC_WRT_COLLATERAL) {
            revert DSCE__ThreshholdCollateralNotMaintained();
        }
    }

    /* Getter functions */

    function getTokenToPriceFeedAddress(
        address tokenAddress
    ) external view returns (address priceFeedAddress) {
        priceFeedAddress = s_tokentoPriceFeedAddress[tokenAddress];
    }

    function getAmountOfTokenForUser(
        address tokenAddress,
        address user
    ) external view returns (uint256 amountOfCollateral) {
        amountOfCollateral = s_amountofTokenForUser[user][tokenAddress];
    }

    function getDSCMintedByUser(
        address user
    ) external view returns (uint256 totalMinted) {
        totalMinted = s_DSCMinted[user];
    }

    function getHealthFactor(
        address user
    ) public view returns (uint256 percentageOfDSCwrtCollateral) {
        percentageOfDSCwrtCollateral = _healthFactor(user);
    }

    function getAcceptedTokenAddresses()
        external
        view
        returns (address[] memory)
    {
        return s_acceptedTokenAddresses;
    }
}

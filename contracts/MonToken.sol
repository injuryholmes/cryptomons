// This should have been deployed to Remix
// We will be using Solidity version 0.5.3
pragma solidity ^0.5.11;
// Importing OpenZeppelin's ERC-721 Implementation
import 'https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol';
// Importing OpenZeppelin's SafeMath Implementation
import 'https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/math/SafeMath.sol';


contract MonToken is ERC721Full {
    using SafeMath for uint;
    // This struct will be used to represent one mon
    struct Mon {
        uint HP;
        uint ATK;
        uint price;
        uint genes;
        uint matronId;
        uint sireId;
        bool onSell;
        bool onShare;
    }
    
    // List of existing mons
    Mon[] public mons;

    // Event that will be emitted whenever a new mon is created
    event Birth(
        address owner,
        uint price,
        uint HP,
        uint ATK,
        uint monId,
        uint matronId,
        uint sireId,
        uint genes
    );

    // Initializing an ERC-721 Token named 'Mons' with a symbol 'MON'
    constructor() ERC721Full("Mons", "MON") public {
    }

    // Fallback function
    function() external payable {
    }

    /** @dev Function to determine a mon's characteristics.
      * @param matron ID of mon's matron (one parent)
      * @param sire ID of mon's sire (other parent)
      * @return The mon's genes in the form of uint8
      */
    function generateMonGenes(
        uint matron,
        uint sire
    )
        internal
        pure
        returns (uint)
    {
        return uint(matron.add(sire)) % 6 + 1;
    }

    /** @dev Function to create a new mon
      * @param matron ID of new mon's matron (one parent)
      * @param sire ID of new mon's sire (other parent)
      * @param monOwner Address of new mon's owner
      * @return The new mon's ID
      */
    function createMon(
        uint matron,
        uint sire,
        address monOwner
    )
        internal
        returns (uint)
    {
        require(monOwner != address(0));
        uint newGenes = generateMonGenes(matron, sire);
        uint hp;
        uint atk;
        uint price;
        
        if (matron == 0 && sire==0) {
            hp = 2;
            atk = 1;
            price = 1;
        } else {
            hp = mons[matron].HP + mons[sire].HP;
            atk = mons[matron].ATK + mons[sire].ATK;
            price = mons[matron].price+mons[sire].price - 1;
        }
        
        Mon memory newMon = Mon({
            price: price,
            HP: hp,
            ATK: atk,
            genes: newGenes,
            matronId: matron,
            sireId: sire,
            onSell: false,
            onShare: false
        });
        uint newMonId = mons.push(newMon).sub(1);
        super._mint(monOwner, newMonId);
        emit Birth(
            monOwner,
            newMon.price,
            newMon.HP,
            newMon.ATK,
            newMonId,
            newMon.matronId,
            newMon.sireId,
            newMon.genes
        );
        return newMonId;
    }
    
    /** @dev Function to allow user to collect a new mon (calls createMon())
      * @return The new mon's ID
      */
    function collectMon() external payable returns (uint) {
        require(msg.value == 1 ether);
        return createMon(0, 0, msg.sender);
    }
    
    
    /** @dev Function to approve the contract to perfrom transer later.
    * @param id ID of Mon want to put on market
    */
    function putOnMarket(uint id) external {
        require(msg.sender==ownerOf(id));
        approve(address(this), id);
        mons[id].onSell = true;
    }
    
    /** @dev Function to allow user to buy a mon from another user
    * @param id ID of Mon want to buy
    */
    function buyMon(uint id) public payable {
        require(id < mons.length);
        require(msg.value > mons[id].price);
        address addr = ownerOf(id);
        address payable seller = address(uint160(addr));
        this.safeTransferFrom(addr, msg.sender, id);
        mons[id].onSell = false;
        seller.transfer(msg.value);
        
    }
    
    /** @dev Function to share one owned Mon
    * @param id ID of Mon want to share
    */
    function share(uint id) public {
        require(ownerOf(id)==msg.sender);
        require(mons[id].onShare == false);
        mons[id].onShare = true;
    }

    function disShare(uint id) public {
        require(ownerOf(id)==msg.sender);
        require(mons[id].onShare == true);
        mons[id].onShare = false;
    }

    event FightRes(
        bool isWin
    );
    
    /** @dev Function to fight 2 mons to create a new one
      * @param fighterA ID of owned Mon to fight
      * @param fighterB ID of opponent's Mon to fight
      */
    function fightMon(uint fighterA, uint fighterB) external payable {
        require(msg.value == 0.05 ether);
        require(ownerOf(fighterA) == msg.sender && ownerOf(fighterB) != msg.sender);
        uint hp_a = mons[fighterA].HP;
        uint atk_a = mons[fighterA].ATK;
        uint hp_b = mons[fighterB].HP;
        uint atk_b = mons[fighterB].ATK;
        while(hp_a > 0 && hp_b > 0) {
            hp_a = hp_a.sub(atk_b);
            hp_b = hp_b.sub(atk_a);
        }
        if (hp_a <= 0) {
            approve(address(this),fighterA);
            address addr = ownerOf(fighterB);
            this.safeTransferFrom(msg.sender, addr, fighterA);
            emit FightRes(
                false
            );
        } else {
            mons[fighterA].price += 2;
            mons[fighterA].HP += 3;
            mons[fighterA].ATK += 1;
            emit FightRes(
                true
            );
        }
    }
    
    /** @dev Function to breed 2 mons to create a new one
      * @param matronId ID of new mon's matron (one parent)
      * @param sireId ID of new mon's sire (other parent)
      * @return The new mon's ID
      */
    function breedMons(uint256 matronId, uint256 sireId) external payable returns (uint256) {
        require(msg.value == 0.05 ether);
        require(
            (ownerOf(matronId)==msg.sender && ownerOf(sireId)==msg.sender) || 
            (mons[matronId].onShare && ownerOf(sireId)==msg.sender) ||
            (ownerOf(matronId)==msg.sender && mons[sireId].onShare==true)
        );
        return createMon(matronId, sireId, msg.sender);
    }
    
    // convert the address to string, inorder to send to vue 
    function addressToString(uint id) internal view returns(string memory) {
        address _addr = ownerOf(id);
        bytes32 value = bytes32(uint256(_addr));
        bytes memory alphabet = "0123456789abcdef";
    
        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint(uint8(value[i + 12] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(value[i + 12] & 0x0f))];
        }
        return string(str);
    }
    
    
    /** @dev Function to retrieve a specific mon's details.
      * @param monId ID of the mon who's details will be retrieved
      * @return An array, [mon's ID, mon's genes, matron's ID, sire's ID]
      */
    function getMonDetails(uint monId) external view returns (uint, uint, uint, uint, address, bool, bool,uint) {
        Mon storage mon = mons[monId];
        return (monId, mon.genes, mon.matronId, mon.sireId, ownerOf(monId),mon.onSell, mon.onShare,mon.price);
    }
  
  
    /** @dev Function to get a list of owned mons' IDs
      * @return A uint array which contains IDs of all owned mons
      */
    function ownedMons() external view returns(uint[] memory) {
        uint monCount = balanceOf(msg.sender);
        if (monCount == 0) {
            return new uint256[](0);
        } else {
            uint[] memory result = new uint[](monCount);
            uint totalMons = mons.length;
            uint resultIndex = 0;
            uint monId = 0;
            while (monId < totalMons) {
                if (ownerOf(monId) == msg.sender) {
                    result[resultIndex] = monId;
                    resultIndex = resultIndex.add(1);
                }
                monId = monId.add(1);
            }
            return result;
        }
    }
     /** @dev Function to get a list of unowned mons' IDs
      * @return A uint array which contains IDs of all unowned mons which are on market
      */
    function unOwnedMons() external view returns(uint[] memory) {
        uint monCount = mons.length - balanceOf(msg.sender);
        if (monCount == 0) {
            return new uint[](0);
        } else {
            uint[] memory result = new uint[](monCount);
            uint totalMons = mons.length;
            uint resultIndex = 0;
            uint monId = 0;
            while (monId < totalMons) {
                if (ownerOf(monId) != msg.sender) {
                    result[resultIndex] = monId;
                    resultIndex = resultIndex.add(1);
                }
                monId = monId.add(1);
            }
            return result;
        }
    }
    
    
}
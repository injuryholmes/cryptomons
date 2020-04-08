<template>
  <b-container class="mb-5">
    <b-row class="header-row">
      <b-col>
        <h1>CryptoMons</h1>
        <p>Collect and breed digital Mons.</p>
        <p>My wallet address: {{account}}</p>
      </b-col>
    </b-row>

    <b-row>
      <b-col class="action-container text-center">
        <h4>Collect a random Mon</h4>
        <img :src="unknownMonImg" class="unknown-mon">
        <b-button type="button" v-on:click="collectMon">Collect</b-button>
        <p>Each collection costs 1 Ether</p>
      </b-col>
      <b-col cols="2" class="middle-container">
        <img v-if="isLoading" src="https://media.giphy.com/media/Gm7LdndVpiCs0/giphy.gif">
        <h3 v-if="!isLoading">or</h3>
      </b-col>

      <b-col class="action-container">
        <h4>Buy a Mon from the Market</h4>
        <b-form>
          <b-form-group id="monToBuy"
                        label="want by Mon ID:"
                        label-for="monToBuy">
            <b-form-input id="monToBuy"
                          v-model="monToBuy"
                          required
                          placeholder="Enter Mon's ID">
            </b-form-input>
          </b-form-group>
          <b-form-group id="buyMonPrice"
                        label="Price to pay:"
                        label-for="buyMonPrice">
            <b-form-input id="buyMonPrice"
                          v-model="buyMonPrice"
                          required
                          placeholder="Enter the price willing to buy">
            </b-form-input>
          </b-form-group>
          <b-button v-on:click="buyMon(buyMonPrice)" type="button">Buy Mon</b-button>
          <p>Check the ID and price carefully</p>
        </b-form>
      </b-col>
    </b-row>
    <hr>
    <b-row>
      <b-col class="action-container">
        <h4>Breed two of the Mons you own to make a new one!</h4>
        <b-form>
          <b-form-group id="matron"
                        label="Matron ID:"
                        label-for="matron">
            <b-form-input id="matron"
                          v-model="matron"
                          required
                          placeholder="Enter Matron ID">
            </b-form-input>
          </b-form-group>
          <b-form-group id="sire"
                        label="Sire ID:"
                        label-for="sire">
            <b-form-input id="sire"
                          v-model="sire"
                          required
                          placeholder="Enter Sire ID">
            </b-form-input>
          </b-form-group>
          <b-button v-on:click="breedMons" type="button">Breed Mons</b-button>
          <p>Breeding Mons cost 0.05 Ether</p>
        </b-form>
      </b-col>
      <b-col cols="2" class="middle-container">
        <img v-if="isBreeding" src="https://media.giphy.com/media/DRfu7BT8ZK1uo/giphy.gif">
        <h3 v-if="!isBreeding">or</h3>
      </b-col>

      <b-col class="action-container">
        <h4>Fight your Mons with other Mons on Market</h4>
        <b-form>
          <b-form-group id="fighterA"
                        label="Your Mon ID:"
                        label-for="fighterA">
            <b-form-input id="fighterA"
                          v-model="fighterA"
                          required
                          placeholder="Enter Mon's ID">
            </b-form-input>
          </b-form-group>
          <b-form-group id="fighterB"
                        label="opponent Mon's ID:"
                        label-for="fighterB">
            <b-form-input id="fighterB"
                          v-model="fighterB"
                          required
                          placeholder="Enter opponent Mon's ID">
            </b-form-input>
          </b-form-group>
          <b-button v-on:click="fightMons" type="button">Fight Mons</b-button>
          <p>Fighting Mons cost 0.05 Ether</p>
        </b-form>
      </b-col>

    </b-row>

    <hr>
    <h2 class="mb-5">Owned Mons</h2>

    <b-row v-if="mons.length == 0">
      <b-col>
        <h2>No Mons owned yet!</h2>
      </b-col>
    </b-row>

    <b-row v-for="i in Math.ceil(mons.length / 3)" v-bind:key="i">
      <b-col cols="4" v-for="item in mons.slice((i - 1) * 3, i * 3)"
             v-bind:item="item"
             v-bind:key="item.id">
        <b-card style="height:530px;" class="mb-2">
          <b-img thumbnail fluid :src="item.url" class="image"/>
          <p class="card-text mt-2 text-center">
            <b>ID:</b> {{ item.id }}
            <br>
            <b>Price:</b> {{ item.price }}
            <br>
            <b>Origin:</b>
            <span v-if="item.matron == 0 && item.sire == 0">Collected</span>
            <span v-else>{{ item.matron }} & {{ item.sire }}</span>
            <b-button v-if="!item.onSell" v-on:click="putOnMarket(item.id)" type="button">Sell</b-button>
            <b-button :disabled="item.onSell" v-if="item.onSell" type="button">waiting for buyer</b-button>
            <b-button v-if="!item.onShare" v-on:click="shareMon(item.id)" type="button">Share</b-button>
            <b-button v-if="item.onShare" v-on:click="disShareMon(item.id)" type="button">Disable sharing</b-button>
          </p>

        </b-card>
      </b-col>
    </b-row>

    <hr>
    <h2 class="mb-5">Market Mons(excluding yours)</h2>

    <b-row v-if="marketMons.length == 0">
      <b-col>
        <h2>No Mons owned yet!</h2>
      </b-col>
    </b-row>

    <b-row v-for="i in Math.ceil(marketMons.length / 3)" v-bind:key="i">
      <b-col cols="4" v-for="item in marketMons.slice((i - 1) * 3, i * 3)"
             v-bind:item="item"
             v-bind:key="item.id">
        <b-card style="height:530px;" class="mb-2">
          <b-img thumbnail fluid :src="item.url" class="image"/>
          <p class="card-text mt-2 text-center">
            <b>ID:</b> {{ item.id }}
            <br>
            <b>Price:</b> {{ item.price }}
            <br>
            <b>Owner Addr:</b> {{ item.owner.substring(0,10) }}
            <br>
            <b>Origin:</b>
            <span v-if="item.matron == 0 && item.sire == 0">Collected</span>
            <span v-else>{{ item.matron }} & {{ item.sire }}</span>
            <b-button :disabled="!item.onSell" v-if="!item.onSell" type="button">Not for Sale</b-button>
            <b-button :disabled="item.onSell" v-if="item.onSell" type="button">waiting for buyer</b-button>
            <b-button :disabled="!item.onShare" v-if="!item.onShare" type="button">Not sharing </b-button>
            <b-button :disabled="item.onShare" v-if="item.onShare" type="button">In sharing</b-button>
          </p>
        </b-card>
      </b-col>
    </b-row>


  </b-container>
</template>

<script>
import getWeb3 from '../contracts/web3';
import contractAbi from '../contracts/abi';
import Mon1 from './assets/Mon/1.png';
import Mon2 from './assets/Mon/2.png';
import Mon3 from './assets/Mon/3.png';
import Mon4 from './assets/Mon/4.png';
import Mon5 from './assets/Mon/5.png';
import Mon6 from './assets/Mon/6.png';
import MonX from './assets/Mon/unknown.png';

const contractAddress = '0x59B9c38738790bAE41861646CeC586BC21E9050f';
const monsMap = [null, Mon1, Mon2, Mon3, Mon4, Mon5, Mon6];

export default {
  name: 'App',
  data() {
    return {
      web3: null,
      account: null,
      contractInstance: null,
      gene: null,
      matron: null,
      sire: null,
      fighterA: null,
      fighterB: null,
      monToBuy: null,
      buyMonPrice: null,
      unknownMonImg: MonX,
      mons: [],
      marketMons: [],
      isLoading: false,
      isFighting: false,
      isBreeding: false,
    };
  },
  mounted() {
    getWeb3().then((res) => {
      this.web3 = res;
      this.contractInstance = new this.web3.eth.Contract(contractAbi, contractAddress);
      this.web3.eth.getAccounts().then((accounts) => {
        [this.account] = accounts;
        this.refreshMons();
      }).catch((err) => {
        console.log(err, 'err!!');
      });
    });
    let app = this;
    window.ethereum.on('accountsChanged', function (accounts) {
      app.web3.eth.getAccounts().then((accounts) => {
        [app.account] = accounts;
        app.refreshMons();
      }).catch((err) => {
        console.log(err, 'err!!');
      });
    });
  },
  methods: {
    collectMon() {
      this.isLoading = true;
      this.contractInstance.methods.collectMon().send({
        from: this.account,
        value: web3.toWei(1, 'ether'),
      }).then((receipt) => {
        this.addMonFromReceipt(receipt);
        this.isLoading = false;
      }).catch((err) => {
        console.log(err, 'err');
        this.isLoading = false;
      });
    },
    breedMons() {
      this.isBreeding = true;
      this.contractInstance.methods.breedMons(this.matron, this.sire).send({
        from: this.account,
        value: web3.toWei(0.05, 'ether'),
      }).then((receipt) => {
        this.addMonFromReceipt(receipt);
        this.isBreeding = false;
      }).catch((err) => {
        window.alert("Transaction fail! Please select the Mon Id you have owned or in sharing!");
        console.log(err, 'err');
        this.isBreeding = false;
      });
    },
    fightMons() {
      this.isFighting = true;
      this.contractInstance.methods.fightMon(this.fighterA, this.fighterB).send({
        from: this.account,
        value: web3.toWei(0.05, 'ether'),
      }).then((receipt) => {
        let isWin = receipt.events.FightRes.returnValues.isWin;
        if (isWin) {
          window.alert("you win!");
        } else {
          window.alert("you lose the fight and your card belongs to the opponent!");
        }
        this.refreshMons();
        this.isFighting = false;
      }).catch((err)=> {
        console.log(err, 'err');
        this.isFighting = false;
      });
    },
    putOnMarket(id) {
      console.log(id);
      this.contractInstance.methods.putOnMarket(id).send({
        from: this.account,
      }).then((receipt) => {
        this.refreshMons();
      }).catch((err)=> {
        console.log(err, 'err');
      });
    },
    buyMon(buyMonPrice) {
      this.contractInstance.methods.buyMon(this.monToBuy).send({
        from: this.account,
        value: web3.toWei(buyMonPrice, 'ether'),
      }).then((receipt) => {
        this.refreshMons();
      }).catch((err)=> {
        window.alert("please pay enough money to buy the Mon!");
        console.log(err, 'err');
      });
    },
    shareMon(id) {
      this.contractInstance.methods.share(id).send({
        from: this.account,
      }).then((receipt) => {
        this.refreshMons();
      }).catch((err)=> {
        console.log(err, 'err');
      });
    },
    disShareMon(id) {
      this.contractInstance.methods.disShare(id).send({
        from: this.account,
      }).then((receipt) => {
        this.refreshMons();
      }).catch((err)=> {
        console.log(err, 'err');
      });
    },
    refreshMons() {
      this.mons = [];
      this.marketMons = [];
      this.getMons();
      this.getMarketMons();
    },
    getMons() {
      this.isLoading = true;
      this.contractInstance.methods.ownedMons().call({
        from: this.account,
      }).then((receipt) => {
        for (let i = 0; i < receipt.length; i += 1) {
          this.contractInstance.methods.getMonDetails(receipt[i]).call({
            from: this.account,
          }).then((mon) => {
            this.mons.push({
              id: mon[0],
              genes: mon[1],
              matron: mon[2],
              sire: mon[3],
              url: monsMap[mon[1]],
              owner: mon[4],
              onSell: mon[5],
              onShare: mon[6],
              price: mon[7],
            });
          }).catch((err) => {
            console.log(err, 'err');
          });
        }
        this.isLoading = false;
      }).catch((err) => {
        console.log(err, 'err');
        this.isLoading = false;
      });
    },
    getMarketMons() {
      this.isLoading = true;
      this.contractInstance.methods.unOwnedMons().call({
        from: this.account,
      }).then((receipt) => {
        for (let i = 0; i < receipt.length; i += 1) {
          this.contractInstance.methods.getMonDetails(receipt[i]).call({
            from: this.account,
          }).then((mon) => {
            this.marketMons.push({
              id: mon[0],
              genes: mon[1],
              matron: mon[2],
              sire: mon[3],
              url: monsMap[mon[1]],
              owner: mon[4],
              onSell: mon[5],
              onShare: mon[6],
              price: mon[7],
            });
          }).catch((err) => {
            console.log(err, 'err');
          });
        }
        this.isLoading = false;
      }).catch((err) => {
        console.log(err, 'err');
        this.isLoading = false;
      });
    },

    addMonFromReceipt(receipt) {
      this.mons.push({
        id: receipt.events.Birth.returnValues.monId,
        genes: receipt.events.Birth.returnValues.genes,
        matron: receipt.events.Birth.returnValues.matronId,
        sire: receipt.events.Birth.returnValues.sireId,
        url: monsMap[receipt.events.Birth.returnValues.genes],
        owner: receipt.events.Birth.returnValues.monOwner,
        onSell: receipt.events.Birth.returnValues.onSell,
        onShare: receipt.events.Birth.returnValues.onShare,
        price: receipt.events.Birth.returnValues.price,
      });
    },
  },
};
</script>

<style lang="css">
@import url('https://fonts.googleapis.com/css?family=Poppins:400,500');

* {
  font-family: 'Poppins', sans-serif;
}
button {
  width: 100%;
}
.header-row {
  text-align: center;
  margin: 30px 0;
}
.action-container h4 {
  text-align: center;
  margin-bottom: 30px;
}
.action-container p {
  text-align: center;
  margin-top: 10px;
}
.middle-container {
  display: flex;
  justify-content: center;
  align-items: center;
}
.middle-container img {
  height: 100px;
}
.unknown-mon {
  height: 180px;
  width: 180px;
  margin: 9px 0;
}
</style>

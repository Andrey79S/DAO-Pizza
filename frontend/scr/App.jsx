import React, { useEffect, useState } from "react";
import { ethers } from "ethers";

// Put the addresses after deployment or replace with placeholders for now
const TOKEN_ADDRESS = "<REPLACE_TOKEN_ADDRESS>";
const SALE_ADDRESS = "<REPLACE_SALE_ADDRESS>";
const TOKEN_ABI = [
  // minimal ABI snippets we need
  "function name() view returns (string)",
  "function symbol() view returns (string)",
  "function decimals() view returns (uint8)",
  "function balanceOf(address) view returns (uint256)",
  "function allowance(address,address) view returns (uint256)",
  "function transfer(address to, uint256 amount) returns (bool)"
];
const SALE_ABI = [
  "function priceWeiPerToken() view returns (uint256)",
  "function buyTokens() payable",
  "event Bought(address indexed buyer, uint256 ethAmount, uint256 tokensAmount)"
];

export default function App() {
  const [provider, setProvider] = useState();
  const [signer, setSigner] = useState();
  const [account, setAccount] = useState();
  const [tokenContract, setTokenContract] = useState();
  const [saleContract, setSaleContract] = useState();
  const [balance, setBalance] = useState("0");
  const [decimals, setDecimals] = useState(18);
  const [price, setPrice] = useState(null);
  const [buyEth, setBuyEth] = useState("0.01");

  useEffect(() => {
    if (typeof window.ethereum === "undefined") {
      console.log("Please install MetaMask");
      return;
    }
    const p = new ethers.BrowserProvider(window.ethereum);
    setProvider(p);
  }, []);

  useEffect(() => {
    if (!provider) return;
    (async () => {
      const accounts = await provider.send("eth_requestAccounts", []);
      const signerLocal = await provider.getSigner();
      setSigner(signerLocal);
      setAccount(accounts[0]);
    })();
  }, [provider]);

  useEffect(() => {
    if (!signer) return;
    const tokenAddr = TOKEN_ADDRESS;
    const saleAddr = SALE_ADDRESS;
    if (tokenAddr && saleAddr && tokenAddr !== "<REPLACE_TOKEN_ADDRESS>") {
      const token = new ethers.Contract(tokenAddr, TOKEN_ABI, signer);
      const sale = new ethers.Contract(saleAddr, SALE_ABI, signer);
      setTokenContract(token);
      setSaleContract(sale);
    }
  }, [signer]);

  useEffect(() => {
    if (!tokenContract || !account) return;
    (async () => {
      try {
        const d = await tokenContract.decimals();
        setDecimals(d);
        const b = await tokenContract.balanceOf(account);
        setBalance(ethers.formatUnits(b, d));
      } catch (e) {
        console.error(e);
      }
    })();
  }, [tokenContract, account]);

  useEffect(() => {
    if (!saleContract) return;
    (async () => {
      try {
        const p = await saleContract.priceWeiPerToken();
        setPrice(p ? p.toString() : null);
      } catch (e) { console.error(e); }
    })();
  }, [saleContract]);

  async function buy() {
    if (!saleContract) return alert("Sale contract not set. Deploy and update addresses in frontend.");
    const ethValue = buyEth;
    try {
      const tx = await signer.sendTransaction({
        to: saleContract.target ?? saleContract.address,
        value: ethers.parseEther(ethValue)
      });
      await tx.wait();
      alert("Purchase tx sent");
      // refresh balance
      const b = await tokenContract.balanceOf(account);
      setBalance(ethers.formatUnits(b, decimals));
    } catch (e) {
      console.error(e);
      alert("Error: " + (e.message || e));
    }
  }

  return (
    <div style={{ maxWidth: 720, margin: "40px auto", fontFamily: "Arial, sans-serif" }}>
      <h1>DAO Pizza — MVP</h1>
      <p>Account: {account}</p>
      <p>Token balance: {balance}</p>
      <p>Token decimals: {decimals}</p>
      <p>Sale price (wei per token): {price}</p>

      <div style={{ marginTop: 20 }}>
        <input value={buyEth} onChange={(e) => setBuyEth(e.target.value)} />
        <button onClick={buy} style={{ marginLeft: 10 }}>Buy tokens (send ETH)</button>
      </div>

      <p style={{ marginTop: 30, color: "#666" }}>
        После деплоя замени TOKEN_ADDRESS и SALE_ADDRESS в <code>frontend/src/App.jsx</code>.
      </p>
    </div>
  );
      }

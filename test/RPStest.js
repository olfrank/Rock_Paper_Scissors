const { expect } = require("chai");
const { ethers } = require("hardhat");


describe ("RPS contract", () => {
    let RPS, rps, addr1, addr2;

    beforeEach(async ()=>{
        RPS = await ethers.getContractFactory("RPS");
        rps = await RPS.deploy(); // in the parenthesis, input contructor parameters
        [ addr1, addr2 ] = await ethers.getSigners()
    })

    describe("enroll", async ()=>{
        it("player2 wager should equal or be greater than the wager set by player1", async()=>{
            // const enteredWager = ethers.utils.parseEther("1");
            
            await rps.connect(addr1).enroll({ value: 50  });
            await rps.connect(addr2).enroll({ value: 50  });
            const wager = await rps.getWager();
            expect (50).to.be.gte(wager);
            expect(await rps.connect(addr1).getContractBalance()).to.equal( "100" );

            // const enteredWager = ethers.utils.parseEther("1");
            // await rps.connect(addr1).enroll({ value: 50  });
            // const wager = await rps.getWager();
            // expect (await rps.connect(addr2).enroll({ value: 50  })).to.be.gte(wager);
        })

        it("should fail if player2 doesnt input an equal or higher wager", async()=>{
            const p1Wager = ethers.utils.parseEther("1");
            const p2Wager = ethers.utils.parseEther("0.5");

            await rps.connect(addr1).enroll({ value: p1Wager });
            await expect(rps.connect(addr2).enroll({value: p2Wager})).to.be.revertedWith("you must enter a value >= player1's bet")
            expect(await rps.connect(addr1).getContractBalance()).to.equal(ethers.utils.parseEther("1"));
        })

    })

    describe("evaluate", async()=>{

        await rps.connect(addr1).enroll({ value: 50  });
        await rps.connect(addr2).enroll({ value: 50  });
        const hashedRock = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("1"));
        const hashedPaper = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("2"));
        const hashedScissors = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("3"));

        it("player1 should win", async () =>{
            const move1 = await rps.connect(addr1).play(hashedPaper);
            const move2 = await rps.connect(addr2).play(hashedRock);
            await rps.evaluate();

            expect(await rps.connect(addr1).getContractBalance()).to.equal( "0" );
            expect()

        })

        it("player2 should win", async () =>{
            const move1 = await rps.connect(addr1).play(hashedPaper);
            const move2 = await rps.connect(addr2).play(hashedScissors);
            await rps.evaluate();

            expect(await rps.connect(addr1).getContractBalance()).to.equal( "0" );
            expect()

        })

        it("player1 should win", async () =>{
            const move1 = await rps.connect(addr1).play(hashedRock);
            const move2 = await rps.connect(addr2).play(hashedScissors);
            await rps.evaluate();

            expect(await rps.connect(addr1).getContractBalance()).to.equal( "0" );
            expect()

        })
    })

    describe("evaluate", async()=>{

        
    });

    describe("pay", async()=>{


    });
        

        

        
    
});


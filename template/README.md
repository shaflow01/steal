# ChainflagCTF出题工具

## 相关链接

- solidctf：https://github.com/chainflag/solidctf
- template：https://github.com/chainflag/solidity-ctf-template/tree/main
- 一篇关于chainflagCTF出题指南：https://www.ctfiot.com/96465.html
- 公开测试链列表：https://chainlist.org/?testnets=true

## 指令

- 克隆项目：`git clone xxx`
- 查看容器执行情况：`docker ps -a`
- 集群部署：`docker-compose pull && docker-compose up -d`
- 删除容器：`docker rm $(docker ps -a -q)`

## 疑问

- [x] 对于不是很熟悉docker-compose的小伙伴，快速入门如下：

  - [x] services中的内容比如ethereum、faucet，是自动化帮你启动容器，根据image获取镜像然后部署
  - [x] ports：`宿主机:docker`
  - [x] container_name：每一个容器名字不得重复，否则报错

- [x] 关于solidctf的Development：如果不给solidctf贡献代码，Development 不需要关心。Development 是给开发solidctf的人看的，而不是使用者

- [x] 逻辑：一个challenge就是一个solidctf，因为基于这个镜像构成的，然后用宿主机的内容映射到docker中

- [x] 关于template

  - [x] docker的默认端口信息（比如端口，文件映射等不需要修改也不能修改），这都是约定好，docker compose不会影响docker里程序的行为。比如下面的例子，`:`右边的内容即docker的信息都不能修改

    ```yml
        volumes:
          - ./flag02.txt:/ctf/flag.txt
          - ./contracts02:/ctf/contracts
          - ./challenge02.yml:/ctf/challenge.yml
    ```

  - [x] 模板默认端口映射是20000:20000，右边的20000不可修改，因为容器里开放的端口号是容器里的程序决定的，不是由docker-compose决定的，docker-compose只是在声明映射规则，不会改变本身容器的行为。例子：20001:20000、20002:20000是指我这个服务器的20001端口对应一个题目，也就是一个容器，也就是一个solidctf，20002同理。

- [x] 关于私链

  - [x] template的docker-compose.yml的ethereum、faucet就是私链，注释了它等同于公开测试链，请看“关于公开测试链”

  - [x] 私链的chain ID可以通过RPC请求获得，所有人的RPC都一样

    ```
    WEB3_PROVIDER_URI=http://ethereum:8545
    ALLOC_ADDRESS_PRIVATE_KEY=1a244b0c79968c206e59c7ac07751c2767ad949c1fdd25a8223d521825e81bd6
    ```

  - [x] 如果想改私链端口，不需要改.env里的请求的docker内部的端口号，只需要改docker-compose 里的外部端口号

- [x] 关于公开测试链：在.env文件中，设置你的测试网URL，不需要私钥。顺便将docker-compose.yml中的（https://github.com/chainflag/solidity-ctf-template/blob/main/docker-compose.yml#L15-L39）这段内容注释掉，原因是：注释了之后，就不会在本地启动私链了，虽然启动的影响不大。

- [x] 其他

  - [x] 无论是Linux还是wsl，都可能出现网络等其他问题，也许使用云服务器进行操作是一个好选择
  - [x] `docker-compose pull && docker-compose up -d`部署之后，容器成功运行，但是nc无法查阅，也许是速度较慢，请稍等。如果仍不行，请重试，问题仍然存在则请查看log日志`docker logs -f "容器ID“`

- [x] 关于.env的私钥：如果是公开测试链，是否有私钥并不影响；如果是自己启的私链，是用来进行POA共识签名出块以及水龙头发送ETH用的

- [x] 关于出多个题：contracts01算一题 => challenge01.yml => 在docker-compose.yml中设置challenge01。这就完成一题，出多个题目则是重复此操作（注意端口映射不重复、题目信息正确映射到宿主机）。例子：部署私链Demo

- [x] 玩家操作

  - [x] 如何访问水龙头获取代币：通过`https:// IP: 8080`访问，具体端口号看出题人实现
  - [x] 如何在metamask添加此私链：知道了链ID与URL即可添加。

- [x] 关于区块链浏览器与查询：可以查询，通过rpc get transaction by hash，暂时没有区块链浏览器

- [x] 关于完成题目：（1）可以检查event是否触发。（2）检验方法一定要写成`isSolved()`吗如下？回答：在你不改solidctf代码的情况下，是的。

  ```solidity
  function isSolved() public view returns (bool);
  ```

- [x] 关于编译器版本：任何版本都支持

- [x] docker-compose.yml的这个代码：用于启动水龙头的命令行参数，详细可以查看水龙头的readme https://github.com/chainflag/eth-faucet

  ```yml
  command: -wallet.provider http://ethereum:8545 -wallet.privkey ${ALLOC_ADDRESS_PRIVATE_KEY} -faucet.minutes 1
  ```

## 部署私链Demo

- 项目结构：每一个contracts01,02就是一个题目，通过nc的不同端口访问的就是不同的内容

- Demo文件内容即本template中的内容

- 操作如下：前提保证docker、iginx、git、python3等工具已启动并可用


1.进入到template目录：`docker-compose pull && docker-compose up -d`

2.查看是否成功部署：`docker ps -a`

```
CONTAINER ID   IMAGE                        COMMAND                  CREATED         STATUS          PORTS                                               NAMES
26dbf7cbee2f   chainflag/eth-faucet:1.1.0   "/app/eth-faucet -wa…"   2 minutes ago   Up 2 minutes    0.0.0.0:8081->8080/tcp, :::8081->8080/tcp           test_eth_faucet
85184dd882ec   chainflag/solidctf:1.0.0     "tini -g -- /entrypo…"   3 minutes ago   Up 45 seconds   0.0.0.0:20002->20000/tcp, :::20002->20000/tcp       test_challenge_02
c4858e2fa5a1   chainflag/solidctf:1.0.0     "tini -g -- /entrypo…"   3 minutes ago   Up 45 seconds   0.0.0.0:20001->20000/tcp, :::20001->20000/tcp       test_challenge_01
0c4ae38c8017   chainflag/fogeth:latest      "/entrypoint.sh"         3 minutes ago   Up 2 minutes    80/tcp, 0.0.0.0:8546->8545/tcp, :::8546->8545/tcp   test_fogeth
```

3.获取链ID：通过RPC工具，本人是使用@[Poseidon](https://github.com/B1ue1nWh1te/Poseidon)工具库获取：

```python
test_url = "http://IP:8546"
chain=Chain(test_url)
print(chain.ChainId)
# 得到链ID：27159
```

4.如果是部署在云服务器，注意在安全组中打开你的云服务器端口，否则玩家无法访问。在本次实验中，我使用阿里云服务器，打开了8546, 8081, 20001, 20002等端口

5.访问：需要等待一会，容器初始化中，大概过3分钟左右即可访问。如果还不行，请重启容器或者查看docker日志排查

```
C:\Users\LEVI>nc IP 20001
Can you make the isSolved() function return true?(test01)

[1] - Create an account which will be used to deploy the challenge contract
[2] - Deploy the challenge contract using your generated account
[3] - Get your flag once you meet the requirement
[4] - Show the contract source code
[-] input your choice: 1
[+] deployer account: 0x751D95b6abfEB866A2D39b758E2AF553dcEcd0d6
[+] token: v4.local.Z0LMTtZXxpRmZYnnWQ7qfSQbaDaapD2ZtK-M04yQ28hUXdvDPlc3Wo8c8eu8UF3ajDkxds9yLKEapy5dq73xX0J_izxzwS5ZFWZEc_ldOKepV669ZSmiiOwamNi1SBbDOx2osdlGOZdOROIPROh8fyxQF1nSSiNyFhIgwgO2t55ZIA.dGVzdDAx
[+] please transfer more than 0.001 test ether to the deployer account for next step
```

6.去水龙头获取测试代币

![](https://moe.photo/images/2023/08/22/_20230822151008.png)

7.在metamask添加测试链

![](https://moe.photo/images/2023/08/22/1.png)

8.完成题解

```
C:\Users\LEVI>nc IP 20001
Can you make the isSolved() function return true?(test01)

[1] - Create an account which will be used to deploy the challenge contract
[2] - Deploy the challenge contract using your generated account
[3] - Get your flag once you meet the requirement
[4] - Show the contract source code
[-] input your choice: 3
[-] input your token: v4.local.Z0LMTtZXxpRmZYnnWQ7qfSQbaDaapD2ZtK-M04yQ28hUXdvDPlc3Wo8c8eu8UF3ajDkxds9yLKEapy5dq73xX0J_izxzwS5ZFWZEc_ldOKepV669ZSmiiOwamNi1SBbDOx2osdlGOZdOROIPROh8fyxQF1nSSiNyFhIgwgO2t55ZIA.dGVzdDAx
[+] flag: flag{flag01}
```

## 部署测试链Demo

将.env的内容补充完毕，然后将docker-compose.yml中的（https://github.com/chainflag/solidity-ctf-template/blob/main/docker-compose.yml#L15-L39）这段内容注释掉，相同的操作部署即可

## 其他

- 建议先在本地比如VM或wsl中模拟操作（可能会存在各种问题比如网络等，不稳定），再到云服务器中操作
- 建议学习docker与docker-compose的知识（包括挂载、映射等），如果不能理解多容器一键部署，此工具使用的时候将会遇到不少问题
- 使用XShell和XFTP等工具登录与传输文件（CTF题目，本地弄好，然后传输到云服务器直接部署即可）
- 可以使用宝塔工具进行云服务器的维护

## 最后

非常感谢@iczc的热情指导与帮助








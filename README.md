# NFT Collection

Colección NFT ERC-721 desarrollada con Solidity, Foundry y OpenZeppelin.

El proyecto implementa minting secuencial, supply limitado, transferencias seguras, approvals, metadata alojada en IPFS, reveal de colección, congelación permanente de metadata y una suite de tests con unit testing, fuzz testing e invariant testing.

El objetivo del proyecto es trabajar el flujo completo de una colección NFT moderna, desde la creación del token on-chain hasta la resolución de metadata e imágenes almacenadas mediante IPFS.

> Proyecto educativo y de portfolio. No ha sido auditado profesionalmente ni está pensado para utilizarse con fondos reales.

---

## Características

- ERC-721 basado en OpenZeppelin.
- Minting mediante `_safeMint()`.
- IDs secuenciales.
- Supply máximo limitado.
- Transferencias seguras.
- `approve()` por NFT.
- `setApprovalForAll()` por colección.
- Metadata mediante `tokenURI()`.
- Metadata e imágenes almacenadas en IPFS.
- Reveal de colección.
- Metadata mutable antes del freeze.
- Freeze permanente de metadata.
- Control administrativo mediante `Ownable`.
- Tests unitarios.
- Fuzz testing.
- Stateful invariant testing.
- Cobertura completa del contrato principal.

---

## Arquitectura

```text
NFTCollection.sol
      │
      ├── ERC-721
      ├── minting
      ├── transfers
      ├── approvals
      ├── MAX_SUPPLY
      ├── tokenURI
      ├── reveal
      └── metadata freeze
             │
             ▼
      Metadata en IPFS
             │
             ▼
          JSON
             │
             ▼
       Imagen en IPFS
```

---

## Minting

Los NFTs se crean mediante:

```solidity
function mint(address to) external onlyOwner
```

Cada token recibe un identificador secuencial:

```text
primer mint  → tokenId 0
segundo mint → tokenId 1
tercer mint  → tokenId 2
```

El contrato utiliza:

```solidity
_safeMint(to, tokenId);
```

en lugar de `_mint()`.

`_safeMint()` comprueba además que, si el receptor es un smart contract, sea compatible con `IERC721Receiver`.

Esto evita enviar accidentalmente NFTs a contratos incapaces de recibirlos correctamente.

---

## Supply máximo

La colección tiene un límite máximo:

```solidity
uint256 public constant MAX_SUPPLY = 100;
```

El contrato comprueba:

```solidity
nextTokenId < MAX_SUPPLY
```

antes de cada mint.

Por tanto, solo pueden crearse los token IDs:

```text
0 ... 99
```

---

## Ownership

ERC-721 permite consultar el propietario de un NFT concreto:

```solidity
ownerOf(tokenId)
```

Ejemplo:

```text
ownerOf(0) → Alice
ownerOf(1) → Bob
```

Mientras que:

```solidity
balanceOf(user)
```

devuelve cuántos NFTs de la colección posee una dirección.

---

## Transferencias

El contrato hereda las transferencias estándar ERC-721:

```solidity
transferFrom(...)
safeTransferFrom(...)
```

La variante segura comprueba también la compatibilidad del receptor cuando el destino es un smart contract.

---

## Approvals

ERC-721 ofrece dos tipos principales de permisos.

### Approval individual

```solidity
approve(operator, tokenId);
```

Autoriza a una dirección a mover un NFT concreto.

Ejemplo:

```text
Alice → owner NFT #7

approve(Bob, #7)

Bob puede mover #7
Bob NO puede mover #8
```

El approval específico se elimina cuando el NFT cambia de propietario.

---

### Operator approval

```solidity
setApprovalForAll(operator, true);
```

Autoriza al operador a mover todos los NFTs que el owner posea dentro de esa colección.

Ejemplo:

```text
Alice
 ├── NFT #0
 ├── NFT #1
 └── NFT #2

setApprovalForAll(Marketplace, true)

Marketplace puede mover:
#0
#1
#2
```

Este mecanismo será especialmente importante para marketplaces NFT.

---

## Metadata

Un NFT no contiene necesariamente su imagen dentro de Ethereum.

El contrato mantiene una URI asociada a cada `tokenId`.

Por ejemplo:

```solidity
tokenURI(0)
```

puede devolver:

```text
ipfs://METADATA_CID/0.json
```

Ese JSON contiene información como:

```json
{
  "name": "Iker Collection #0",
  "description": "NFT #0 from the Iker Collection.",
  "image": "ipfs://IMAGE_CID/0.png",
  "attributes": [
    {
      "trait_type": "Background",
      "value": "Blue"
    },
    {
      "trait_type": "Rarity",
      "value": "Common"
    }
  ]
}
```

Por tanto:

```text
NFT #0
   ↓
tokenURI(0)
   ↓
metadata/0.json
   ↓
image
   ↓
images/0.png
```

---

## IPFS

La metadata y las imágenes pueden almacenarse en IPFS.

IPFS utiliza identificadores basados en contenido llamados CID.

Ejemplo:

```text
images/
└── 0.png
```

puede quedar accesible mediante:

```text
ipfs://IMAGE_CID/0.png
```

Mientras que:

```text
metadata/
└── 0.json
```

puede quedar accesible mediante:

```text
ipfs://METADATA_CID/0.json
```

El contrato no descarga ni valida esos archivos.

Solo almacena y construye la URI que apunta a ellos.

---

## Base URI

El owner puede configurar:

```solidity
setBaseURI(...)
```

Por ejemplo:

```text
base URI:
ipfs://METADATA_CID/

tokenId:
7
```

produce:

```text
ipfs://METADATA_CID/7.json
```

---

## Reveal

La colección soporta un flujo de reveal.

Antes del reveal, la metadata puede apuntar a contenido provisional:

```text
NFT #0 → placeholder
NFT #1 → placeholder
NFT #2 → placeholder
```

Posteriormente:

```solidity
reveal(finalBaseURI);
```

actualiza la base URI a la metadata definitiva.

Flujo:

```text
mint
↓
metadata provisional
↓
reveal
↓
metadata definitiva
```

`reveal()` no crea nuevos NFTs.

Solo cambia la metadata utilizada por tokens que ya existen.

---

## Metadata freeze

Después del reveal, el owner puede ejecutar:

```solidity
freezeMetadata();
```

Una vez congelada:

```text
setBaseURI() ❌
reveal()     ❌
```

La metadata deja de poder modificarse desde el contrato.

Esto permite un flujo como:

```text
metadata provisional
↓
mint
↓
reveal
↓
comprobación
↓
freeze
↓
metadata definitiva e inmutable
```

---

## Seguridad

El proyecto utiliza componentes estándar de OpenZeppelin.

### Safe mint

```solidity
_safeMint()
```

evita enviar NFTs a contratos incompatibles con ERC-721.

### Access control

Las operaciones administrativas importantes utilizan:

```solidity
onlyOwner
```

incluyendo:

```text
mint
setBaseURI
reveal
freezeMetadata
```

### Supply protection

El contrato impide superar:

```solidity
MAX_SUPPLY
```

### Zero address

ERC-721 impide mintear NFTs hacia:

```solidity
address(0)
```

---

## Testing

El proyecto utiliza Foundry.

La suite incluye tests sobre:

- nombre y símbolo;
- minting;
- múltiples mints;
- supply máximo;
- mint a `address(0)`;
- transferencias;
- safe transfers;
- receptores ERC-721 compatibles;
- receptores incompatibles;
- approvals;
- operator approvals;
- revocación de approvals;
- base URI;
- token URI;
- reveal;
- metadata freeze;
- control de acceso;
- fuzz testing;
- invariant testing.

Ejecutar todos los tests:

```bash
forge test
```

Modo verbose:

```bash
forge test -vv
```

---

## Fuzz testing

Se utilizan fuzz tests para probar múltiples valores generados automáticamente por Foundry.

Entre otros:

```text
recipient addresses
mint amounts
transfer recipients
approved operators
unauthorized addresses
operator revocation
```

Esto permite explorar edge cases que no sería práctico escribir manualmente uno por uno.

---

## Invariant testing

El proyecto incluye stateful invariant testing.

Un handler ejecuta secuencias aleatorias de:

```text
mintToAlice
mintToBob
transferAliceToBob
transferBobToAlice
```

Foundry genera múltiples secuencias mientras comprueba reglas que deben mantenerse siempre.

Una ejecución completa produjo:

```text
Runs:     256
Calls:    128,000
Reverts:  0
```

---

## Invariants

### Supply máximo

```text
nextTokenId <= MAX_SUPPLY
```

La colección nunca puede superar el supply máximo.

---

### Todo NFT tiene owner

Para cada token minteado:

```text
ownerOf(tokenId) != address(0)
```

---

### Consistencia de balances

Como el handler solo utiliza Alice y Bob:

```text
balanceOf(Alice)
+
balanceOf(Bob)
=
NFTs minteados
```

Esto comprueba que las transferencias no crean ni destruyen NFTs accidentalmente.

---

## Coverage

Generado mediante:

```bash
forge coverage
```

### Contrato principal

| Métrica | Cobertura |
|---|---:|
| Lines | **100.00% (21/21)** |
| Statements | **100.00% (15/15)** |
| Branches | **100.00% (8/8)** |
| Functions | **100.00% (7/7)** |

El contrato principal `NFTCollection.sol` alcanza cobertura completa en todas las métricas de Foundry.

La suite combina coverage tradicional con fuzz e invariant testing para validar tanto escenarios concretos como secuencias complejas de cambios de estado.

---

## Estructura

```text
nft-collection/
│
├── src/
│   └── NFTCollection.sol
│
├── test/
│   ├── NFTCollection.t.sol
│   ├── NFTCollectionInvariant.t.sol
│   ├── ERC721ReceiverMock.sol
│   └── NonERC721Receiver.sol
│
├── images/
│   └── 0.png
│
├── metadata/
│   └── 0.json
│
├── foundry.toml
├── remappings.txt
└── README.md
```

---

## Instalación

Clonar:

```bash
git clone https://github.com/ikerbotana2002/nft-collection.git
cd nft-collection
```

Instalar dependencias:

```bash
forge install
```

Compilar:

```bash
forge build
```

Ejecutar tests:

```bash
forge test
```

Ejecutar invariant testing:

```bash
forge test --match-contract NFTCollectionInvariantTest -vv
```

Coverage:

```bash
forge coverage
```

---

## Tecnologías

- Solidity
- Foundry
- Forge
- OpenZeppelin Contracts
- ERC-721
- IPFS
- Git
- GitHub

---

## Conceptos trabajados

- ERC-721
- NFT ownership
- token IDs
- safe minting
- safe transfers
- IERC721Receiver
- approvals
- operator approvals
- metadata
- tokenURI
- IPFS
- CID
- reveal mechanisms
- metadata immutability
- fuzz testing
- stateful invariant testing
- smart contract access control

---

## Estado

Proyecto funcional y cubierto mediante unit tests, fuzz testing e invariant testing.

No ha sido auditado profesionalmente.

No debe utilizarse en producción con fondos reales.

---

# English version

## NFT Collection

ERC-721 NFT collection built with Solidity, Foundry and OpenZeppelin.

The project implements sequential minting, limited supply, safe transfers, approvals, IPFS metadata, collection reveal, permanent metadata freezing and an extensive testing suite including unit, fuzz and stateful invariant testing.

The goal is to explore the complete lifecycle of a modern NFT collection, from on-chain ownership to off-chain metadata resolution through IPFS.

---

## Main features

- OpenZeppelin ERC-721.
- Safe minting.
- Sequential token IDs.
- Maximum supply.
- Safe NFT transfers.
- Per-token approvals.
- Collection-wide operator approvals.
- IPFS metadata.
- Custom `tokenURI()`.
- Collection reveal.
- Metadata freeze.
- Owner-controlled administration.
- Unit testing.
- Fuzz testing.
- Stateful invariant testing.
- Full coverage of the main contract.

---

## Architecture

```text
NFTCollection.sol
      │
      ├── ERC-721
      ├── minting
      ├── transfers
      ├── approvals
      ├── MAX_SUPPLY
      ├── tokenURI
      ├── reveal
      └── metadata freeze
             │
             ▼
       IPFS metadata
             │
             ▼
           JSON
             │
             ▼
        IPFS image
```

---

## Minting

NFTs are created through:

```solidity
function mint(address to) external onlyOwner
```

Token IDs are assigned sequentially:

```text
first mint  → tokenId 0
second mint → tokenId 1
third mint  → tokenId 2
```

The contract uses:

```solidity
_safeMint(to, tokenId);
```

instead of `_mint()`.

When the receiver is a smart contract, `_safeMint()` verifies that it correctly implements ERC-721 receiving behavior.

---

## Maximum supply

The collection defines:

```solidity
uint256 public constant MAX_SUPPLY = 100;
```

Only token IDs from:

```text
0 ... 99
```

can ever be minted.

---

## Ownership

ERC-721 tracks ownership per token:

```solidity
ownerOf(tokenId)
```

while:

```solidity
balanceOf(user)
```

returns the number of NFTs owned by an address.

---

## Transfers

The contract supports standard ERC-721 transfers:

```solidity
transferFrom(...)
safeTransferFrom(...)
```

Safe transfers verify ERC-721 compatibility when transferring to smart contracts.

---

## Approvals

### Per-token approvals

```solidity
approve(operator, tokenId);
```

grants permission over one specific NFT.

That approval is cleared when the token is transferred.

### Operator approvals

```solidity
setApprovalForAll(operator, true);
```

allows an operator to manage every NFT owned by a user within the collection.

This mechanism is commonly used by NFT marketplaces.

---

## Metadata

NFT visual data is not stored directly inside the ERC-721 contract.

Instead:

```solidity
tokenURI(tokenId)
```

returns a metadata URI such as:

```text
ipfs://METADATA_CID/0.json
```

The JSON can contain:

```json
{
  "name": "Iker Collection #0",
  "description": "NFT #0 from the Iker Collection.",
  "image": "ipfs://IMAGE_CID/0.png"
}
```

The complete flow is:

```text
NFT
↓
tokenURI
↓
metadata JSON
↓
image URI
↓
IPFS image
```

---

## IPFS

Images and metadata can be stored through IPFS.

IPFS addresses content using a CID.

Example:

```text
ipfs://IMAGE_CID/0.png
```

and:

```text
ipfs://METADATA_CID/0.json
```

The smart contract itself does not fetch these files.

It only exposes the URI.

---

## Reveal mechanism

The collection supports a reveal flow.

Before reveal:

```text
NFTs → placeholder metadata
```

After:

```solidity
reveal(finalBaseURI);
```

the collection points to its final metadata.

Reveal does not mint new tokens.

It changes the metadata reference used by already existing NFTs.

---

## Metadata freeze

The owner can permanently freeze metadata through:

```solidity
freezeMetadata();
```

Once frozen:

```text
setBaseURI() blocked
reveal()     blocked
```

This provides an optional final immutability stage after the collection has been revealed and verified.

---

## Security

The project uses OpenZeppelin contracts and ERC-721 standard protections.

Relevant mechanisms include:

- `_safeMint()`;
- safe transfers;
- ERC721Receiver checks;
- owner-only administrative operations;
- maximum supply enforcement;
- zero-address mint protection;
- metadata freezing.

---

## Testing

The project includes:

- minting tests;
- transfer tests;
- approval tests;
- operator tests;
- receiver compatibility tests;
- metadata tests;
- reveal tests;
- freeze tests;
- access-control tests;
- fuzz tests;
- stateful invariant tests.

Run:

```bash
forge test
```

---

## Fuzz testing

Foundry generates multiple inputs for scenarios involving:

- recipient addresses;
- mint quantities;
- transfer recipients;
- operators;
- unauthorized accounts;
- revoked approvals.

---

## Stateful invariant testing

The invariant handler executes randomized sequences of:

```text
mintToAlice
mintToBob
transferAliceToBob
transferBobToAlice
```

A complete run produced:

```text
Runs:     256
Calls:    128,000
Reverts:  0
```

---

## Invariants

The suite verifies properties such as:

```text
nextTokenId <= MAX_SUPPLY
```

```text
every minted NFT has a valid owner
```

and:

```text
Alice balance + Bob balance
=
total number of minted NFTs
```

---

## Coverage

Generated with:

```bash
forge coverage
```

### Main contract

| Metric | Coverage |
|---|---:|
| Lines | **100.00% (21/21)** |
| Statements | **100.00% (15/15)** |
| Branches | **100.00% (8/8)** |
| Functions | **100.00% (7/7)** |

`NFTCollection.sol` reaches full coverage across all reported Foundry metrics.

---

## Installation

Clone:

```bash
git clone https://github.com/ikerbotana2002/nft-collection.git
cd nft-collection
```

Install dependencies:

```bash
forge install
```

Build:

```bash
forge build
```

Run tests:

```bash
forge test
```

Run invariant testing:

```bash
forge test --match-contract NFTCollectionInvariantTest -vv
```

Generate coverage:

```bash
forge coverage
```

---

## Tech stack

- Solidity
- Foundry
- Forge
- OpenZeppelin
- ERC-721
- IPFS
- Git
- GitHub

---

## Topics explored

- ERC-721
- NFT ownership
- token IDs
- safe minting
- safe transfers
- IERC721Receiver
- approvals
- operator approvals
- metadata
- tokenURI
- IPFS
- CIDs
- reveal mechanisms
- metadata immutability
- fuzz testing
- invariant testing
- smart contract security

---

## Status

Functional educational and portfolio project with automated unit, fuzz and invariant testing.

The contracts have not undergone a professional security audit and should not be used with real funds.
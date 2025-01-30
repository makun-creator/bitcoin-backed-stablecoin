;; Title: Bitcoin-Backed Stablecoin System (BBS)
;; Summary:
;; A decentralized, overcollateralized stablecoin system powered by Bitcoin.
;; Description:
;; This smart contract enables users to deposit Bitcoin as collateral to mint stablecoins, ensuring stability through a robust overcollateralization mechanism.
;; It includes features for collateral management, debt repayment, liquidation, and price oracle integration.
;; Designed for security and transparency, the system maintains a minimum collateralization ratio and liquidation threshold to protect against market volatility.
;; Administrative functions allow for price updates and oracle management, ensuring the system remains resilient and up-to-date.

;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-INSUFFICIENT-COLLATERAL (err u1001))
(define-constant ERR-BELOW-MINIMUM (err u1002))
(define-constant ERR-INVALID-AMOUNT (err u1003))
(define-constant ERR-POSITION-NOT-FOUND (err u1004))
(define-constant ERR-ALREADY-LIQUIDATED (err u1005))
(define-constant ERR-HEALTHY-POSITION (err u1006))
(define-constant ERR-PRICE-EXPIRED (err u1007))

;; System Parameters
(define-constant MIN-COLLATERAL-RATIO u150) ;; Minimum collateralization ratio (150%)
(define-constant LIQUIDATION-RATIO u120)    ;; Liquidation threshold (120%)
(define-constant MIN-DEPOSIT u1000000)      ;; Minimum deposit amount (satoshis)
(define-constant PRICE-VALIDITY-PERIOD u144) ;; Price validity period (144 blocks ~ 1 day)

;; Data Variables
(define-data-var contract-owner principal tx-sender) ;; Contract owner
(define-data-var price-oracle principal tx-sender)   ;; Price oracle address
(define-data-var total-supply uint u0)               ;; Total stablecoin supply
(define-data-var btc-price uint u0)                  ;; Current BTC price
(define-data-var last-price-update uint block-height) ;; Last price update block

;; Data Maps
(define-map user-positions
    principal
    {
        collateral: uint,  ;; User's collateral in satoshis
        debt: uint,        ;; User's stablecoin debt
        last-update: uint  ;; Last update block
    }
)

(define-map liquidation-history
    principal
    {
        timestamp: uint,              ;; Liquidation timestamp
        collateral-liquidated: uint,  ;; Collateral liquidated
        debt-repaid: uint             ;; Debt repaid
    }
)

;; Read-Only Functions

;; Get user's position details
(define-read-only (get-position (user principal))
    (map-get? user-positions user)
)

;; Calculate user's collateralization ratio
(define-read-only (get-collateral-ratio (user principal))
    (let (
        (position (unwrap! (get-position user) (err u0)))
        (collateral-value (* (get collateral position) (var-get btc-price)))
        (debt-value (* (get debt position) u100000000))
    )
        (if (is-eq (get debt position) u0)
            (ok u0)
            (ok (/ (* collateral-value u100) debt-value)))
    )
)
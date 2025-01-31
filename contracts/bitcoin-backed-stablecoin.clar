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
(define-constant MAX-DEPOSIT u100000000000) ;; Maximum deposit amount (satoshis)
(define-constant MAX-BTC-PRICE u1000000000000) ;; Maximum BTC price (e.g., $1,000,000)

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
(define-data-var last-price-update uint stacks-block-height) ;; Last price update block

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

;; Fetch current BTC price
(define-read-only (get-current-price)
    (ok (var-get btc-price))
)

;; Private Functions

;; Ensure the BTC price is up-to-date
(define-private (check-price-freshness)
    (if (< (- stacks-block-height (var-get last-price-update)) PRICE-VALIDITY-PERIOD)
        (ok true)
        ERR-PRICE-EXPIRED
    )
)

;; Validate minimum collateral deposit
(define-private (check-min-collateral (amount uint))
    (if (>= amount MIN-DEPOSIT)
        (ok true)
        ERR-BELOW-MINIMUM
    )
)

;; Check if a position is healthy (above liquidation threshold)
(define-private (check-position-health (user principal))
    (let (
        (ratio (unwrap! (get-collateral-ratio user) (err u0)))
    )
        (if (< ratio MIN-COLLATERAL-RATIO)
            ERR-INSUFFICIENT-COLLATERAL
            (ok true))
    )
)

;; Helper function to check if a principal is valid
(define-private (is-valid-principal (user principal))
    (let ((buff (unwrap! (to-consensus-buff? user) false))) ;; Unwrap the optional buff
        (is-eq (len buff) u20) ;; Check if the buff length is 20 bytes
    )
)

;; Public Functions

;; Deposit Bitcoin collateral
(define-public (deposit-collateral (amount uint))
    (begin
        (try! (check-min-collateral amount))
        (asserts! (<= amount MAX-DEPOSIT) ERR-INVALID-AMOUNT)
        (let (
            (current-position (default-to 
                { collateral: u0, debt: u0, last-update: stacks-block-height }
                (get-position tx-sender)
            ))
            (new-collateral (+ amount (get collateral current-position)))
        )
            ;; Ensure no overflow occurred
            (asserts! (>= new-collateral (get collateral current-position)) ERR-INVALID-AMOUNT)
            (map-set user-positions tx-sender
                {
                    collateral: new-collateral,
                    debt: (get debt current-position),
                    last-update: stacks-block-height
                }
            )
            (ok true))
    )
)


;; Mint stablecoins against deposited collateral
(define-public (mint-stablecoin (amount uint))
    (begin
        (try! (check-price-freshness))
        (let (
            (current-position (unwrap! (get-position tx-sender) ERR-POSITION-NOT-FOUND))
            (new-debt (+ amount (get debt current-position)))
            (collateral-value (* (get collateral current-position) (var-get btc-price)))
            (required-collateral (* new-debt MIN-COLLATERAL-RATIO))
        )
            (asserts! (>= collateral-value required-collateral) ERR-INSUFFICIENT-COLLATERAL)
            
            (map-set user-positions tx-sender
                {
                    collateral: (get collateral current-position),
                    debt: new-debt,
                    last-update: stacks-block-height
                }
            )
            (var-set total-supply (+ (var-get total-supply) amount))
            (ok true))
    )
)

;; Repay stablecoin debt
(define-public (repay-stablecoin (amount uint))
    (let (
        (current-position (unwrap! (get-position tx-sender) ERR-POSITION-NOT-FOUND))
    )
        (asserts! (>= (get debt current-position) amount) ERR-INVALID-AMOUNT)
        
        (map-set user-positions tx-sender
            {
                collateral: (get collateral current-position),
                debt: (- (get debt current-position) amount),
                last-update: stacks-block-height
            }
        )
        (var-set total-supply (- (var-get total-supply) amount))
        (ok true)
    )
)

;; Withdraw Bitcoin collateral
(define-public (withdraw-collateral (amount uint))
    (let (
        (current-position (unwrap! (get-position tx-sender) ERR-POSITION-NOT-FOUND))
    )
        (asserts! (>= (get collateral current-position) amount) ERR-INVALID-AMOUNT)
        
        (map-set user-positions tx-sender
            {
                collateral: (- (get collateral current-position) amount),
                debt: (get debt current-position),
                last-update: stacks-block-height
            }
        )
        (try! (check-position-health tx-sender))
        (ok true)
    )
)

;; Liquidate an undercollateralized position
(define-public (liquidate-position (user principal))
    (begin
        (try! (check-price-freshness))
        (let (
            (position (unwrap! (get-position user) ERR-POSITION-NOT-FOUND))
            (ratio (unwrap! (get-collateral-ratio user) ERR-POSITION-NOT-FOUND))
        )
            (asserts! (< ratio LIQUIDATION-RATIO) ERR-HEALTHY-POSITION)
            
            ;; Record liquidation
            (map-set liquidation-history user
                {
                    timestamp: stacks-block-height,
                    collateral-liquidated: (get collateral position),
                    debt-repaid: (get debt position)
                }
            )
            
            ;; Clear position
            (map-set user-positions user
                {
                    collateral: u0,
                    debt: u0,
                    last-update: stacks-block-height
                }
            )
            
            ;; Update total supply
            (var-set total-supply (- (var-get total-supply) (get debt position)))
            (ok true))
    )
)

;; Admin Functions

;; Update BTC price (only callable by price oracle)
(define-public (set-price (new-price uint))
    (begin
        (asserts! (is-eq tx-sender (var-get price-oracle)) ERR-NOT-AUTHORIZED)
        (asserts! (and (> new-price u0) (< new-price MAX-BTC-PRICE)) ERR-INVALID-AMOUNT)
        (var-set btc-price new-price)
        (var-set last-price-update stacks-block-height)
        (ok true))
)

;; Set new price oracle (only callable by contract owner)
(define-public (set-price-oracle (new-oracle principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (asserts! (is-valid-principal new-oracle) ERR-NOT-AUTHORIZED)
        (var-set price-oracle new-oracle)
        (ok true))
)
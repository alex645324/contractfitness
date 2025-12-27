**CLEAN PROMPT**

Define and enforce the system flow for account creation, contract creation, and contract management.

Account creation:

* Allow users to create an account by entering a **user name** and pressing **Confirm**.
* Lock the user name after account creation.

Contract creation:

* To create a contract, the user must complete **all remaining setup fields**.
* Pressing **Confirm** again creates a contract and links both users to it.

Contract management:

* Each contract displays a progress marker (`0/60` or `0/90`) that users work toward.
* To advance progress for a day, the user must complete **all daily tasks**.
* After completing all tasks, pressing **Confirm** in the management section updates progress for **all contracts linked to that user**.

Failure behavior:

* If the user does **not** complete all daily tasks:

  * Progress for each linked contract **decrements by 1**.
  * Progress may go **negative**.
  * The contract **penalties** count increments (missed days).

Daily reset:

* Tasks reset every day.
* Progress evaluation runs daily based on task completion.

Constraints:

* Do not add new flows or UI.
* Implement exactly this behavior and nothing more.

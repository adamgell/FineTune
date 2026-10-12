# Automation API (proposal implementation)

FineTune automation uses a versioned, current-user local interface. API v1 requests carry `apiVersion`, `id`, `method`, and `params`. Responses repeat the ID and contain exactly one `result` or `error`. Request IDs must be nonempty and at most 128 UTF-8 bytes. See `automation-fixtures/v1.json` for complete envelopes.

App targets use `target.appId` (FineTune's persistence ID), optionally `instanceId` for one current process. Device targets use `target.deviceUID` and `direction` (`output` or `input`). IDs remain stable across profiles; process IDs are never saved as stable identity.

Volume uses 0–100 gain percent; boost is separately 1x/2x/3x/4x. Slider steps use FineTune's nonlinear mapping and are explicitly distinguished from gain-percent steps. EQ gains are -12 through +12 dB. All numeric inputs must be finite.

`applied` means a completed control update; `stored` means persisted inactive intent; `pending` includes an operation ID and does not promise hardware success. Errors include invalid_request, unsupported_version, unknown_method, invalid_parameter, not_found, ambiguous_target, unavailable, permission_required, conflict, busy, timeout, internal_error.

Existing URL commands retain compatibility. Their `set-volumes` range is 0–100; values up to 400 are not accepted by the current handler. Set boost independently through the new API.

Full command descriptors, transport enablement, access restrictions, and subscription semantics will accompany the control-service/transport implementation. No transport is enabled by this protocol-types change alone.

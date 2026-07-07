# API Implementation Plan for Community & Posts

This document outlines the plan to build the fully functional APIs based on the `community_api_requirements.md` file. The database tables and migrations have already been created.

## 1. Configure Eloquent Models
I will configure the 9 `Community*` models I generated earlier. This involves:
- Adding the `$fillable` arrays to allow mass assignment safely.
- Setting up all the Eloquent relationships (`hasMany`, `belongsTo`) so we can easily fetch a post with its author and comments, or a group with its members.

## 2. API Controllers
Since your API controllers live in `app/Http/Controllers/Api/`, I propose creating the following controllers to handle the logic cleanly:

- **`CommunityGroupController`**
  - `index()`: Fetch user's joined groups (`GET /api/v1/groups/me`)
  - `explore()`: Search & explore groups, filtering out joined and premium ones (`GET /api/v1/groups`)
  - `show()`: Fetch specific group details (`GET /api/v1/groups/{groupId}`)
  - `join()`: Join a public group (`POST /api/v1/groups/{groupId}/join`)
  - `requestJoin()`: Request to join a private group (`POST /api/v1/groups/{groupId}/request-join`)
  - `members()`: Fetch group members (`GET /api/v1/groups/{groupId}/members`)

- **`CommunityPostController`**
  - `index()`: Fetch group posts (`GET /api/v1/groups/{groupId}/posts`)
  - `store()`: Create a standard post (`POST /api/v1/groups/{groupId}/posts`)
  - `update()`: Edit a post (`PUT /api/v1/posts/{postId}`)
  - `destroy()`: Delete a post (`DELETE /api/v1/posts/{postId}`)
  - `like()`: Toggle like (`POST /api/v1/posts/{postId}/like`)
  - `share()`: Track share (`POST /api/v1/posts/{postId}/share`)

- **`CommunityPollController`**
  - `store()`: Create a poll post (`POST /api/v1/groups/{groupId}/polls`)
  - `vote()`: Vote on a poll (`POST /api/v1/polls/{pollId}/vote`)

- **`CommunityCommentController`**
  - `index()`: Fetch comments (`GET /api/v1/posts/{postId}/comments`)
  - `store()`: Add a comment (`POST /api/v1/posts/{postId}/comments`)
  - `update()`: Edit a comment (`PUT /api/v1/comments/{commentId}`)
  - `destroy()`: Delete a comment (`DELETE /api/v1/comments/{commentId}`)

- **`CommunityMediaController`**
  - `upload()`: Upload media and return URL (`POST /api/v1/media/upload`)

## 3. JSON Formatting (API Resources)
To guarantee the API responses exactly match the JSON structure defined in `community_api_requirements.md`, I will use Laravel **API Resources** (e.g., `GroupResource`, `PostResource`, `CommentResource`). This ensures the app developers receive the precise keys and formats they expect, without leaking sensitive database columns.

## 4. API Routes
I will register all the above endpoints in `routes/api.php` grouped under an authentication middleware (e.g., `auth:sanctum` or whatever token system you currently use for APIs).

---

> [!IMPORTANT]  
> **Please review this plan.** If this structure looks good, just give me the command to begin execution and I will start writing the backend code!

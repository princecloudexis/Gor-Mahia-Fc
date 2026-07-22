# Community & Posts API Requirements

This document outlines the REST API endpoints required to support the Community and Create Post features in the Gor Mahia FC app. This can be shared directly with the backend developer.

## 1. Groups & Branches (Community)

### 1.1 Fetch User's Joined Groups
**Endpoint:** `GET /api/v1/groups/me`
**Description:** Returns a list of groups/branches the current user is a member of.
**Response:**
```json
{
  "status": 200,
  "success": true,
  "message": "User's joined groups fetched successfully",
  "data": [
    {
      "id": "group_123",
      "name": "Nairobi Group",
      "description": "The official branch for all Gor Mahia fans residing in and around Nairobi. We meet every matchday!",
      "imageUrl": "https://cdn.example.com/groups/nairobi.jpg",
      "requiredMembershipTier": "free",
      "postPermission": "all",
      "visibility": "public",
      "membersCount": 1245,
      "createdAt": "2024-10-12T10:00:00Z",
      "type": "public",
      "isJoined": true,
      "joinStatus": "approved"
    }
  ]
}
```

### 1.2 Search & Explore Groups
**Endpoint:** `GET /api/v1/groups?search={query}&cursor={lastGroupId}&limit=6`
**Description:** Returns a list of all groups for infinite scrolling. 
*Backend Logic:* This should **exclude** groups the user has already joined (`status == 'approved'`). If the user has a **"pending"** join request for a private group, that group MUST STILL be included in this Discover feed so the mobile app can display it as "Pending". AND it must **exclude** any groups that have a `requiredMembershipTier` higher than the user's current purchased membership plan (e.g., free members should not see premium-only groups).
**Response:**
```json
{
  "status": 200,
  "success": true,
  "message": "Groups fetched successfully",
  "data": [
    {
      "id": "group_456",
      "name": "Kisumu Group",
      "description": "Exclusive group for Kisumu branch members to discuss events and match viewings.",
      "imageUrl": "https://cdn.example.com/groups/kisumu.jpg",
      "requiredMembershipTier": "premium",
      "postPermission": "admin_only",
      "visibility": "public",
      "membersCount": 892,
      "createdAt": "2024-11-05T14:30:00Z",
      "type": "private",
      "isJoined": false,
      "joinStatus": null
    }
  ],
  "meta": {
    "nextCursor": "group_456",
    "hasNextPage": true
  }
}
```

### 1.3 Join a Public Group
**Endpoint:** `POST /api/v1/groups/{groupId}/join`
**Description:** Adds the user to a public group immediately.
**Response:**
```json
{
  "status": 200,
  "success": true,
  "message": "Joined successfully"
}
```

### 1.4 Request to Join a Private Group
**Endpoint:** `POST /api/v1/groups/{groupId}/request-join`
**Description:** Submits a join request for a private group, pending admin approval.
**Response:**
```json
{
  "status": 201,
  "success": true,
  "message": "Join request sent successfully"
}
```

## 2. Group Details

### 2.1 Fetch Group Details
**Endpoint:** `GET /api/v1/groups/{groupId}`
**Description:** Fetch full details of a specific group.
**Response:**
```json
{
  "status": 200,
  "success": true,
  "message": "Group details fetched successfully",
  "data": {
    "id": "group_123",
    "name": "Nairobi Group",
    "description": "The official branch for all Gor Mahia fans residing in and around Nairobi. We meet every matchday!",
    "imageUrl": "https://cdn.example.com/groups/nairobi.jpg",
    "requiredMembershipTier": "free",
    "postPermission": "all",
    "visibility": "public",
    "membersCount": 1245,
    "createdAt": "2024-10-12T10:00:00Z",
    "type": "public",
    "isJoined": true,
    "joinStatus": "approved"
  }
}
```

### 2.2 Fetch Group Posts
**Endpoint:** `GET /api/v1/groups/{groupId}/posts?cursor={lastPostId}&limit=5`
**Description:** Fetches posts within a specific group for infinite scrolling.
> [!IMPORTANT]
> - **Public Groups:** If the group is public and the user is NOT a member (`isJoined = false`), the API should return a maximum of 5 posts and set `hasNextPage: false`. Do not allow pagination beyond the first 5 posts for non-members.
> - **Private Groups:** If the group is private and the user is NOT a member, the API must return a `403 Forbidden` error.
**Response:**
```json
{
  "status": 200,
  "success": true,
  "message": "Group posts fetched successfully",
  "data": [
    {
      "id": "post_789",
      "authorId": "user_123",
      "postedBy": "user",
      "authorName": "John Doe",
      "authorAvatar": "https://cdn.example.com/avatars/john.jpg",
      "content": "What a match today!",
      "media": [
        {
          "url": "https://cdn.example.com/images/match.jpg",
          "type": "image"
        }
      ],
      "timestamp": "2026-07-07T12:00:00Z",
      "updated_at": "2026-07-07T14:30:00Z",
      "isPoll": false,
      "likesCount": 1200,
      "commentsCount": 34,
      "sharesCount": 12,
      "isLikedByMe": true,
      "shareContent": {
        "type": "media",
        "content": "What a match today!",
        "media": [
          {
            "url": "https://cdn.example.com/images/match.jpg",
            "type": "image"
          }
        ]
      }
    }
  ],
  "meta": {
    "nextCursor": "post_789",
    "hasNextPage": true
  }
}
```

### 2.3 Fetch Group Members
**Endpoint:** `GET /api/v1/groups/{groupId}/members?cursor={lastUserId}&limit=6`
**Description:** Fetches a paginated list of members for the group using infinite scrolling.
> [!IMPORTANT]
> **Membership Required:** Only users who have joined the group (`isJoined = true`) can view the member list. If a non-member attempts to fetch members for either a public or private group, the API must return a `403 Forbidden` error.
**Response:**
```json
{
  "status": 200,
  "success": true,
  "message": "Group members fetched successfully",
  "data": [
    {
      "id": "user_789",
      "name": "John Doe",
      "avatarUrl": "https://cdn.example.com/avatars/john.jpg",
      "role": "admin"
    }
  ],
  "meta": {
    "nextCursor": "user_789",
    "hasNextPage": true
  }
}
```

## 3. Posts & Media Creation

### 3.1 Fetch GIFs
**Endpoint:** `GET /api/v1/gifs?category={category}&search={query}&limit=6`
**Description:** Fetches a list of admin-curated GIFs that can be attached to posts and comments. No authentication is strictly required, but usually used within the app flow.
**Response:**
```json
{
  "status": 200,
  "success": true,
  "message": "GIFs fetched successfully",
  "data": [
    {
      "id": "1",
      "title": "Goal Celebration",
      "category": "sports",
      "url": "https://cdn.example.com/gifs/goal.gif"
    }
  ],
  "meta": {
    "nextCursor": "1",
    "hasNextPage": false
  }
}
```

### 3.2 Upload Media (Pre-signed URL or direct upload)
**Endpoint:** `POST /api/v1/media/upload`
**Description:** Uploads an image or video and returns the CDN URL. Should support multiple files.
**Payload:** `multipart/form-data` (file)
**Response:**
```json
{
  "status": 200,
  "success": true,
  "message": "Media uploaded successfully",
  "data": {
    "url": "https://cdn.example.com/images/post_img_123.jpg",
    "type": "image"
  }
}
```

### 3.3 Create a Standard Post
**Endpoint:** `POST /api/v1/groups/{groupId}/posts`
**Description:** Creates a new text/media/gif post in the specified group. Note: `media` and `gif_id` are mutually exclusive.
> [!IMPORTANT]
> **Membership Required:** A user MUST be a member of the group (`isJoined = true`) to create a post. If a non-member tries to post, return a `403 Forbidden` error.
**Request Payload:**
```json
{
  "content": "What a match today! #GorMahia",
  "media": [
    {
      "url": "https://cdn.example.com/images/post_img_123.jpg",
      "type": "image"
    }
  ]
}
```
*(Or with a GIF)*
```json
{
  "content": "What a goal!",
  "gif_id": 1
}
```
**Response:**
```json
{
  "status": 201,
  "success": true,
  "message": "Post created successfully",
  "data": {
    "id": "post_790",
    "authorId": "user_123",
    "postedBy": "user",
    "authorName": "John Doe",
    "authorAvatar": "https://cdn.example.com/avatars/john.jpg",
    "content": "What a match today! #GorMahia",
    "media": [
      {
        "url": "https://cdn.example.com/images/post_img_123.jpg",
        "type": "image"
      }
    ],
    "timestamp": "2026-07-07T12:05:00Z",
    "isPoll": false,
    "likesCount": 0,
    "commentsCount": 0,
    "sharesCount": 0,
    "isLikedByMe": false,
    "shareContent": {
      "type": "media",
      "content": "What a match today! #GorMahia",
      "media": [
        {
          "url": "https://cdn.example.com/images/post_img_123.jpg",
          "type": "image"
        }
      ]
    }
  }
}
```

### 3.4 Create a Poll Post
**Endpoint:** `POST /api/v1/groups/{groupId}/polls`
**Description:** Creates a poll post in the specified group.
> [!IMPORTANT]
> **Membership Required:** A user MUST be a member of the group (`isJoined = true`) to create a poll. If a non-member tries to post, return a `403 Forbidden` error.
> 
> **Poll Expiry (`expiresAt`):** The backend MUST calculate and return an `expiresAt` timestamp in the future based on the `durationHours` requested. If the backend returns a date in the past, the frontend app will instantly lock the poll and mark it as "Expired," preventing users from voting!
**Request Payload:**
```json
{
  "question": "Who was the Man of the Match?",
  "options": ["Player A", "Player B", "Player C"],
  "durationHours": 24
}
```
**Response:**
```json
{
  "status": 201,
  "success": true,
  "message": "Poll created successfully",
  "data": {
    "id": "post_791",
    "authorId": "user_123",
    "postedBy": "user",
    "authorName": "John Doe",
    "authorAvatar": "https://cdn.example.com/avatars/john.jpg",
    "content": "Who was the Man of the Match?",
    "isPoll": true,
    "pollData": {
      "id": "poll_1",
      "options": [
        { "id": "opt_1", "text": "Player A", "votes": 0 },
        { "id": "opt_2", "text": "Player B", "votes": 0 },
        { "id": "opt_3", "text": "Player C", "votes": 0 }
      ],
      "hasVoted": false,
      "expiresAt": "2030-12-31T23:59:59Z",
      "totalVotes": 0
    },
    "timestamp": "2026-07-07T12:05:00Z",
    "likesCount": 0,
    "commentsCount": 0,
    "sharesCount": 0,
    "isLikedByMe": false,
    "shareContent": {
      "type": "poll",
      "content": "Who was the Man of the Match?"
    }
  }
}
```

### 3.5 Edit a Post
**Endpoint:** `PUT /api/v1/posts/{postId}`
**Description:** Updates the content or media of an existing post. Only the author can edit. You can also pass `gif_id` instead of `media`.
**Request Payload:**
```json
{
  "content": "Updated content here",
  "media": [
    {
      "url": "https://cdn.example.com/images/post_img_123.jpg",
      "type": "image"
    }
  ]
}
```
**Response:**
```json
{
  "status": 200,
  "success": true,
  "message": "Post updated successfully",
  "data": {
    "id": "post_790",
    "content": "Updated content here",
    "timestamp": "2026-07-07T12:05:00Z"
  }
}
```

### 3.6 Delete a Post
**Endpoint:** `DELETE /api/v1/posts/{postId}`
**Description:** Soft deletes a post. Only the author or a group admin can delete.
**Response:**
```json
{
  "status": 200,
  "success": true,
  "message": "Post deleted successfully"
}
```

## 4. Post Interactions (Likes, Comments, Shares)

> [!IMPORTANT]  
> **Membership Required:** A user MUST be a member of the group (`isJoined = true`) to interact with posts. If a non-member tries to like, comment, or vote in a public group, the backend should reject the request with a `403 Forbidden` error.
> *(Note: Sharing a post using the Share endpoint is allowed for non-members if the group is public, to encourage app growth).*

> [!NOTE]  
> **Count Formatting:** The backend MUST return all engagement counts (`likesCount`, `commentsCount`, `sharesCount`, `pollVotesCount`) as raw **integers** (e.g., `1500`, not `"1.5k"`). The frontend mobile app automatically handles formatting these numbers into abbreviations like `1.5k` or `1M`.

Once a user views posts in a group, they can interact with them. The following endpoints support these actions:

### 4.1 Toggle Like on a Post
**Endpoint:** `POST /api/v1/posts/{postId}/like`
**Description:** Toggles the like status of a post for the current user.
**Response:**
```json
{
  "status": 200,
  "success": true,
  "message": "Like toggled successfully",
  "data": {
    "liked": true,
    "likesCount": 144
  }
}
```

### 4.2 Fetch Comments on a Post
**Endpoint:** `GET /api/v1/posts/{postId}/comments?cursor={lastCommentId}&limit=5`
**Description:** Fetches top-level comments for a specific post using infinite scrolling. (Backend should only return comments where `parent_id` is null).
**Response:**
```json
{
  "status": 200,
  "success": true,
  "message": "Comments fetched successfully",
  "data": [
    {
      "id": "comment_1",
      "userId": "user_789",
      "userName": "John Doe",
      "userImage": "https://cdn.example.com/avatars/john.jpg",
      "content": "Great match today!",
      "gif": {
        "id": "1",
        "url": "https://cdn.example.com/gifs/goal.gif"
      },
      "parent_id": null,
      "repliesCount": 0,
      "timestamp": "2026-07-07T12:00:00Z",
      "updated_at": "2026-07-07T14:30:00Z"
    }
  ],
  "meta": {
    "nextCursor": "comment_1",
    "hasNextPage": false
  }
}
```

### 4.3 Add a Comment
**Endpoint:** `POST /api/v1/posts/{postId}/comments`
**Description:** Adds a new comment to a post. Can include a text `content` and/or `gif_id`. If this is a reply to an existing comment, include the `parent_id`.
**Request Payload:**
```json
{
  "content": "Great match today!",
  "gif_id": 1,
  "parent_id": 1
}
```
**Response:**
```json
{
  "status": 201,
  "success": true,
  "message": "Comment added successfully",
  "data": {
    "id": "comment_2",
    "userId": "user_123",
    "userName": "John Doe",
    "userImage": "https://cdn.example.com/avatars/john.jpg",
    "content": "Great match today!",
    "gif": {
      "id": "1",
      "url": "https://cdn.example.com/gifs/goal.gif"
    },
    "parent_id": 1,
    "repliesCount": 0,
    "timestamp": "2026-07-07T12:10:00Z"
  }
}
```

### 4.4 Fetch Replies for a Comment
**Endpoint:** `GET /api/v1/comments/{commentId}/replies?cursor={lastReplyId}&limit=5`
**Description:** Fetches the paginated list of replies for a specific top-level comment.
**Response:**
```json
{
  "status": 200,
  "success": true,
  "message": "Replies fetched successfully",
  "data": [
    {
      "id": "comment_3",
      "userId": "user_999",
      "userName": "Jane Smith",
      "userImage": "https://cdn.example.com/avatars/jane.jpg",
      "content": "I completely agree!",
      "gif": null,
      "parent_id": 1,
      "repliesCount": 0,
      "timestamp": "2026-07-07T12:15:00Z",
      "updated_at": "2026-07-07T12:15:00Z"
    }
  ],
  "meta": {
    "nextCursor": "comment_3",
    "hasNextPage": false
  }
}
```

### 4.5 Track/Generate Share Link
**Endpoint:** `POST /api/v1/posts/{postId}/share`
**Description:** Records a share action to increment the share count and returns a public deep link and full post resource.
**Response:**
```json
{
  "status": 200,
  "success": true,
  "message": "Share link generated successfully",
  "data": {
    "shareUrl": "https://gormahia.app/api/v1/posts/{postId}/public",
    "sharesCount": 10,
    "post": {
      "id": "post_789",
      "content": "What a match today!",
      "media": []
    }
  }
}
```

### 4.6 Fetch a Single Post (Public)
**Endpoint:** `GET /api/v1/posts/{postId}/public`
**Description:** Public endpoint to fetch a single post's details. Used when a shared link is opened (no authentication required).
**Response:**
```json
{
  "status": 200,
  "success": true,
  "message": "Post fetched successfully",
  "data": {
    "id": "post_789",
    "authorName": "John Doe",
    "content": "What a match today!",
    "shareContent": {
      "type": "media",
      "content": "What a match today!"
    }
  }
}
```

### 4.7 Vote on a Poll
**Endpoint:** `POST /api/v1/polls/{pollId}/vote`
**Description:** Submits the user's vote for a poll.
**Payload:**
```json
{
  "optionIndex": 1
}
```
**Response:**
```json
{
  "status": 200,
  "success": true,
  "message": "Voted successfully"
}
```

### 4.8 Edit a Comment
**Endpoint:** `PUT /api/v1/comments/{commentId}`
**Description:** Updates an existing comment. Only the author can edit.
**Request Payload:**
```json
{
  "content": "Updated comment text",
  "gif_id": 2
}
```
**Response:**
```json
{
  "status": 200,
  "success": true,
  "message": "Comment updated successfully",
  "data": {
    "id": "comment_2",
    "content": "Updated comment text",
    "timestamp": "2026-07-07T12:10:00Z"
  }
}
```

### 4.9 Delete a Comment
**Endpoint:** `DELETE /api/v1/comments/{commentId}`
**Description:** Soft deletes a comment. Only the author or a group admin can delete.
**Response:**
```json
{
  "status": 200,
  "success": true,
  "message": "Comment deleted successfully"
}
```

---

## 5. In-App Notifications

These endpoints power the in-app notifications screen. The backend automatically creates these notifications whenever a user's post is liked/commented on, or their comment receives a reply.

### 5.1 Fetch Notifications
**Endpoint:** `GET /api/v1/notifications?limit=15&page=1`
**Description:** Fetches the authenticated user's chronological notification feed.
**Response:**
```json
{
  "status": 200,
  "success": true,
  "message": "Notifications fetched successfully",
  "data": [
    {
      "id": "9b1c9...-...",
      "title": "New Like",
      "body": "John Doe liked your post.",
      "type": "like",
      "reference_id": "post_123",
      "sender_id": "user_456",
      "senderAvatar": "https://cdn.example.com/avatars/john.jpg",
      "isRead": false,
      "timestamp": "2026-07-10T12:00:00Z"
    }
  ],
  "meta": {
    "currentPage": 1,
    "lastPage": 5,
    "total": 72
  }
}
```

### 5.2 Mark Notification as Read
**Endpoint:** `POST /api/v1/notifications/{id}/read`
**Description:** Marks a specific notification as read so it no longer appears as "unread" in the UI.
**Response:**
```json
{
  "status": 200,
  "success": true,
  "message": "Notification marked as read"
}
```

---

> [!TIP]
> **For the Frontend Developer:**
> - **Group Membership State:** All Group API responses now include `isJoined` (boolean) and `joinStatus` (string: `'approved'`, `'pending'`, or `null`).
> - **Pending Requests in UI:** If a user opens a private group and their `joinStatus` is `'pending'`, immediately swap the "Join" button for a disabled "Requested" button. 
> - **Displaying Errors:** If a user tries to interact with a group they haven't joined (create post, like, comment, vote), the API will return a `403 Forbidden` with a user-friendly message (e.g., `"Please join the group first to create a post"` or `"Your request to join this private group is pending approval."`). You can safely display this `message` directly to the user in a Toast or Snackbar.
> - **UI State:** For public groups, if the user is not a member (`isJoined == false`), it is recommended to replace the "Create Post" or comment input boxes with a "Join Group to Interact" button to seamlessly guide the user.
> - **Pagination Limits:** The default `limit` for fetching posts, comments, members, and explore groups is now `6`.

> [!TIP]
> **For the Backend Developer:**
> - Group creation and group images (`imageUrl`) will be managed via the backend Admin Panel. The app only needs to consume this data.
> - **Membership Filtering:** The backend must handle filtering in the Explore Groups API. If a group requires a "premium" membership, it should not be returned in the API response for users on a "free" plan.
> - Ensure all endpoints require JWT Bearer token authentication (except the new Public post fetch route `GET /api/v1/posts/{postId}/public` and `GET /api/v1/gifs` which can be unauthenticated).
> - **Access Control:** For private groups, ensure that non-members cannot fetch posts or members. For public groups, non-members can fetch posts, but they MUST NOT be allowed to create posts, like, comment, share, or vote.
> - Consider implementing WebSocket or Server-Sent Events (SSE) in the future for real-time chat/post updates.
> - **Cascade Deletion:** When a parent comment is soft-deleted, ensure that all of its child replies are also automatically soft-deleted to prevent orphaned data from breaking the frontend.
> - **Push Notifications:** Set up notification triggers for engagement. Push a notification to the post author when someone likes or comments on their post, and to the parent comment author when someone replies to their comment.

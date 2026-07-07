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
      "membersCount": 1245,
      "createdAt": "2024-10-12T10:00:00Z",
      "type": "public"
    }
  ]
}
```

### 1.2 Search & Explore Groups
**Endpoint:** `GET /api/v1/groups?search={query}&cursor={lastGroupId}&limit=20`
**Description:** Returns a list of all groups for infinite scrolling. 
*Backend Logic:* This should **exclude** groups the user has already joined, AND it must **exclude** any groups that have a `requiredMembershipTier` higher than the user's current purchased membership plan (e.g., free members should not see premium-only groups).
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
      "membersCount": 892,
      "createdAt": "2024-11-05T14:30:00Z",
      "type": "private"
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
    "membersCount": 1245,
    "createdAt": "2024-10-12T10:00:00Z",
    "type": "public"
  }
}
```

### 2.2 Fetch Group Posts
**Endpoint:** `GET /api/v1/groups/{groupId}/posts?cursor={lastPostId}&limit=20`
**Description:** Fetches posts within a specific group for infinite scrolling.
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
      "isPoll": false,
      "likesCount": 1200,
      "commentsCount": 34,
      "sharesCount": 12,
      "pollVotesCount": 0,
      "isLikedByMe": true
    }
  ],
  "meta": {
    "nextCursor": "post_789",
    "hasNextPage": true
  }
}
```

### 2.3 Fetch Group Members
**Endpoint:** `GET /api/v1/groups/{groupId}/members?cursor={lastUserId}&limit=20`
**Description:** Fetches a paginated list of members for the group using infinite scrolling.
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

### 3.1 Upload Media (Pre-signed URL or direct upload)
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

### 3.2 Create a Standard Post
**Endpoint:** `POST /api/v1/groups/{groupId}/posts`
**Description:** Creates a new text/media post in the specified group.
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
**Response:**
```json
{
  "status": 201,
  "success": true,
  "message": "Post created successfully",
  "data": {
    "id": "post_790",
    "authorId": "user_123",
    "authorName": "John Doe",
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
    "sharesCount": 0
  }
}
```

### 3.3 Create a Poll Post
**Endpoint:** `POST /api/v1/groups/{groupId}/polls`
**Description:** Creates a poll post in the specified group.
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
    "authorName": "John Doe",
    "content": "Who was the Man of the Match?",
    "isPoll": true,
    "pollData": {
      "options": [
        { "id": "opt_1", "text": "Player A", "votes": 0 },
        { "id": "opt_2", "text": "Player B", "votes": 0 },
        { "id": "opt_3", "text": "Player C", "votes": 0 }
      ],
      "expiresAt": "2026-07-08T12:05:00Z",
      "totalVotes": 0
    },
    "timestamp": "2026-07-07T12:05:00Z",
    "likesCount": 0,
    "commentsCount": 0,
    "sharesCount": 0
  }
}
```

### 3.4 Edit a Post
**Endpoint:** `PUT /api/v1/posts/{postId}`
**Description:** Updates the content or media of an existing post. Only the author can edit.
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

### 3.5 Delete a Post
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
**Endpoint:** `GET /api/v1/posts/{postId}/comments?cursor={lastCommentId}&limit=20`
**Description:** Fetches comments for a specific post using infinite scrolling.
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
      "content": "Great match today!",
      "timestamp": "2026-07-07T12:00:00Z"
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
**Description:** Adds a new comment to a post.
**Request Payload:**
```json
{
  "content": "Great match today!"
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
    "content": "Great match today!",
    "timestamp": "2026-07-07T12:10:00Z"
  }
}
```

### 4.4 Track/Generate Share Link
**Endpoint:** `POST /api/v1/posts/{postId}/share`
**Description:** Records a share action to increment the share count and optionally returns a deep link.
**Response:**
```json
{
  "status": 200,
  "success": true,
  "message": "Share link generated successfully",
  "data": {
    "shareUrl": "https://gormahia.app/p/{postId}",
    "sharesCount": 10
  }
}
```

### 4.5 Vote on a Poll
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

### 4.6 Edit a Comment
**Endpoint:** `PUT /api/v1/comments/{commentId}`
**Description:** Updates an existing comment. Only the author can edit.
**Request Payload:**
```json
{
  "content": "Updated comment text"
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

### 4.7 Delete a Comment
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

> [!TIP]
> **For the Backend Developer:**
> - Group creation and group images (`imageUrl`) will be managed via the backend Admin Panel. The app only needs to consume this data.
> - **Membership Filtering:** The backend must handle filtering in the Explore Groups API. If a group requires a "premium" membership, it should not be returned in the API response for users on a "free" plan.
> - Ensure all endpoints require JWT Bearer token authentication.
> - For private groups, ensure that unauthorized users cannot fetch posts or members.
> - Consider implementing WebSocket or Server-Sent Events (SSE) in the future for real-time chat/post updates.

-- ActiveLoop Database Creation Script
-- Drop database if exists and create fresh
DROP DATABASE IF EXISTS activeloop;
CREATE DATABASE activeloop;
USE activeloop;

-- Users table
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    location VARCHAR(255),
    role ENUM('participant', 'volunteer', 'admin', 'group_manager', 'support_technician') DEFAULT 'participant',
    status ENUM('active', 'banned') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Community Groups table (Project 2)
CREATE TABLE community_groups (
    group_id INT AUTO_INCREMENT PRIMARY KEY,
    group_name VARCHAR(255) NOT NULL,
    description TEXT,
    location VARCHAR(255),
    group_manager_id INT,
    created_by INT NOT NULL,
    status ENUM('active', 'pending', 'rejected') DEFAULT 'pending',
    join_policy ENUM('open', 'closed') DEFAULT 'open',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (group_manager_id) REFERENCES users(user_id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Group Memberships table (Project 2)
CREATE TABLE group_memberships (
    membership_id INT AUTO_INCREMENT PRIMARY KEY,
    group_id INT NOT NULL,
    user_id INT NOT NULL,
    role_in_group ENUM('member', 'volunteer', 'manager') DEFAULT 'member',
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES community_groups(group_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE KEY unique_group_user (group_id, user_id)
);

-- Events table
CREATE TABLE events (
    event_id INT AUTO_INCREMENT PRIMARY KEY,
    group_id INT,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    event_date DATE NOT NULL,
    event_time TIME NOT NULL,
    location VARCHAR(255) NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    max_participants INT NOT NULL,
    created_by INT NOT NULL,
    status ENUM('active', 'cancelled') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES community_groups(group_id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Event registrations
CREATE TABLE registrations (
    registration_id INT AUTO_INCREMENT PRIMARY KEY,
    event_id INT NOT NULL,
    participant_id INT NOT NULL,
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('registered', 'cancelled', 'no_show') DEFAULT 'registered',
    FOREIGN KEY (event_id) REFERENCES events(event_id) ON DELETE CASCADE,
    FOREIGN KEY (participant_id) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE KEY unique_event_participant (event_id, participant_id)
);

-- Volunteer roles for events
CREATE TABLE volunteer_roles (
    role_id INT AUTO_INCREMENT PRIMARY KEY,
    event_id INT NOT NULL,
    role_name VARCHAR(100) NOT NULL,
    description TEXT,
    volunteers_needed INT DEFAULT 1,
    FOREIGN KEY (event_id) REFERENCES events(event_id) ON DELETE CASCADE
);

-- Volunteer assignments
CREATE TABLE volunteer_assignments (
    assignment_id INT AUTO_INCREMENT PRIMARY KEY,
    event_id INT NOT NULL,
    volunteer_id INT NOT NULL,
    role_name VARCHAR(100) NOT NULL,
    assignment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('assigned', 'completed', 'cancelled') DEFAULT 'assigned',
    hours_logged DECIMAL(5,2) DEFAULT 0.00,
    FOREIGN KEY (event_id) REFERENCES events(event_id) ON DELETE CASCADE,
    FOREIGN KEY (volunteer_id) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE KEY unique_event_volunteer_role (event_id, volunteer_id, role_name)
);

-- Race times and results
CREATE TABLE race_times (
    result_id INT AUTO_INCREMENT PRIMARY KEY,
    event_id INT NOT NULL,
    participant_id INT NOT NULL,
    start_time TIME,
    finish_time TIME,
    position INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (event_id) REFERENCES events(event_id) ON DELETE CASCADE,
    FOREIGN KEY (participant_id) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE KEY unique_event_participant_result (event_id, participant_id)
);

-- Photo galleries (Project 2 - Community Features)
CREATE TABLE photos (
    photo_id INT AUTO_INCREMENT PRIMARY KEY,
    event_id INT NOT NULL,
    group_id INT,
    uploader_id INT NOT NULL,
    filename VARCHAR(255) NOT NULL,
    original_filename VARCHAR(255) NOT NULL,
    caption TEXT,
    privacy_level ENUM('public', 'group', 'private') DEFAULT 'public',
    upload_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('active', 'flagged', 'hidden', 'deleted') DEFAULT 'active',
    FOREIGN KEY (event_id) REFERENCES events(event_id) ON DELETE CASCADE,
    FOREIGN KEY (group_id) REFERENCES community_groups(group_id) ON DELETE SET NULL,
    FOREIGN KEY (uploader_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Photo tags (Project 2)
CREATE TABLE photo_tags (
    tag_id INT AUTO_INCREMENT PRIMARY KEY,
    photo_id INT NOT NULL,
    tagged_user_id INT NOT NULL,
    tagged_by_user_id INT NOT NULL,
    tag_status ENUM('pending', 'approved', 'rejected') DEFAULT 'approved',
    tagged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (photo_id) REFERENCES photos(photo_id) ON DELETE CASCADE,
    FOREIGN KEY (tagged_user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (tagged_by_user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE KEY unique_photo_user_tag (photo_id, tagged_user_id)
);

-- Photo likes (Project 2)
CREATE TABLE photo_likes (
    like_id INT AUTO_INCREMENT PRIMARY KEY,
    photo_id INT NOT NULL,
    user_id INT NOT NULL,
    liked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (photo_id) REFERENCES photos(photo_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE KEY unique_photo_user_like (photo_id, user_id)
);

-- Photo comments (Project 2)
CREATE TABLE photo_comments (
    comment_id INT AUTO_INCREMENT PRIMARY KEY,
    photo_id INT NOT NULL,
    user_id INT NOT NULL,
    comment_text TEXT NOT NULL,
    posted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('active', 'hidden', 'deleted') DEFAULT 'active',
    FOREIGN KEY (photo_id) REFERENCES photos(photo_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Gamification - User Points (Project 2)
CREATE TABLE user_points (
    point_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    group_id INT,
    points INT NOT NULL,
    point_type ENUM('event_completion', 'volunteer_hours', 'challenge_completion', 'badge_earned') NOT NULL,
    reference_id INT, -- Can reference event_id, assignment_id, etc.
    description TEXT,
    awarded_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (group_id) REFERENCES community_groups(group_id) ON DELETE SET NULL
);

-- Gamification - Badges (Project 2)
CREATE TABLE badges (
    badge_id INT AUTO_INCREMENT PRIMARY KEY,
    badge_name VARCHAR(100) NOT NULL,
    badge_description TEXT,
    badge_icon VARCHAR(255),
    criteria_type ENUM('events_attended', 'volunteer_hours', 'consecutive_events', 'special_achievement') NOT NULL,
    criteria_value INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User Badges (Project 2)
CREATE TABLE user_badges (
    user_badge_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    badge_id INT NOT NULL,
    earned_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (badge_id) REFERENCES badges(badge_id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_badge (user_id, badge_id)
);

-- Challenges (Project 2)
CREATE TABLE challenges (
    challenge_id INT AUTO_INCREMENT PRIMARY KEY,
    challenge_name VARCHAR(255) NOT NULL,
    description TEXT,
    challenge_type ENUM('individual', 'group', 'system_wide') DEFAULT 'individual',
    start_date DATE,
    end_date DATE,
    target_value INT,
    target_type ENUM('events', 'volunteer_hours', 'distance', 'time') NOT NULL,
    reward_points INT DEFAULT 0,
    status ENUM('active', 'completed', 'cancelled') DEFAULT 'active',
    created_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(user_id) ON DELETE CASCADE
);

-- User Challenge Progress (Project 2)
CREATE TABLE user_challenge_progress (
    progress_id INT AUTO_INCREMENT PRIMARY KEY,
    challenge_id INT NOT NULL,
    user_id INT NOT NULL,
    current_value INT DEFAULT 0,
    completed BOOLEAN DEFAULT FALSE,
    completed_date TIMESTAMP NULL,
    FOREIGN KEY (challenge_id) REFERENCES challenges(challenge_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE KEY unique_challenge_user (challenge_id, user_id)
);

-- Helpdesk System (Project 2)
CREATE TABLE support_requests (
    request_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    subject VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    category ENUM('technical', 'account', 'event', 'general') DEFAULT 'general',
    priority ENUM('low', 'medium', 'high', 'urgent') DEFAULT 'medium',
    status ENUM('new', 'open', 'stalled', 'resolved') DEFAULT 'new',
    assigned_to INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_to) REFERENCES users(user_id) ON DELETE SET NULL
);

-- Support Request Replies (Project 2)
CREATE TABLE support_replies (
    reply_id INT AUTO_INCREMENT PRIMARY KEY,
    request_id INT NOT NULL,
    user_id INT NOT NULL,
    reply_text TEXT NOT NULL,
    is_staff_reply BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (request_id) REFERENCES support_requests(request_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Custom Themes (Project 2)
CREATE TABLE group_themes (
    theme_id INT AUTO_INCREMENT PRIMARY KEY,
    group_id INT NOT NULL,
    theme_name VARCHAR(100) NOT NULL,
    primary_color VARCHAR(7) DEFAULT '#007bff',
    secondary_color VARCHAR(7) DEFAULT '#6c757d',
    background_color VARCHAR(7) DEFAULT '#ffffff',
    text_color VARCHAR(7) DEFAULT '#212529',
    font_family VARCHAR(100) DEFAULT 'system-ui',
    background_image VARCHAR(255),
    custom_css TEXT,
    is_active BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES community_groups(group_id) ON DELETE CASCADE
);

-- Event Locations (Project 2)
CREATE TABLE event_locations (
    location_id INT AUTO_INCREMENT PRIMARY KEY,
    location_name VARCHAR(255) NOT NULL UNIQUE,
    address VARCHAR(500),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Event Location Mapping (Project 2)
CREATE TABLE event_location_mapping (
    mapping_id INT AUTO_INCREMENT PRIMARY KEY,
    event_id INT NOT NULL,
    start_location_id INT,
    end_location_id INT,
    FOREIGN KEY (event_id) REFERENCES events(event_id) ON DELETE CASCADE,
    FOREIGN KEY (start_location_id) REFERENCES event_locations(location_id) ON DELETE SET NULL,
    FOREIGN KEY (end_location_id) REFERENCES event_locations(location_id) ON DELETE SET NULL
);

-- Online Shop Products (Project 2)
CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    description TEXT,
    category ENUM('apparel', 'accessories', 'barcode_id', 'gift_cards') NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    image_url VARCHAR(500),
    is_event_specific BOOLEAN DEFAULT FALSE,
    event_id INT NULL,
    stock_quantity INT DEFAULT 0,
    status ENUM('active', 'inactive', 'out_of_stock') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (event_id) REFERENCES events(event_id) ON DELETE SET NULL
);

-- Product Variants (sizes, colors, etc.)
CREATE TABLE product_variants (
    variant_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    variant_name VARCHAR(100) NOT NULL, -- e.g., "Size", "Color"
    variant_value VARCHAR(100) NOT NULL, -- e.g., "Large", "Red"
    price_modifier DECIMAL(10, 2) DEFAULT 0.00,
    stock_quantity INT DEFAULT 0,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
);

-- Orders
CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    status ENUM('pending', 'confirmed', 'shipped', 'delivered', 'cancelled') DEFAULT 'pending',
    payment_method ENUM('credit_card', 'debit_card', 'gift_card') DEFAULT 'credit_card',
    shipping_address TEXT,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Order Items
CREATE TABLE order_items (
    item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    variant_id INT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
    FOREIGN KEY (variant_id) REFERENCES product_variants(variant_id) ON DELETE SET NULL
);

-- Gift Cards
CREATE TABLE gift_cards (
    card_id INT AUTO_INCREMENT PRIMARY KEY,
    card_code VARCHAR(50) UNIQUE NOT NULL,
    initial_value DECIMAL(10, 2) NOT NULL,
    current_balance DECIMAL(10, 2) NOT NULL,
    purchased_by INT,
    recipient_email VARCHAR(255),
    status ENUM('active', 'redeemed', 'expired') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at DATE,
    FOREIGN KEY (purchased_by) REFERENCES users(user_id) ON DELETE SET NULL
);

-- Create indexes for better performance
CREATE INDEX idx_events_date ON events(event_date);
CREATE INDEX idx_events_type ON events(event_type);
CREATE INDEX idx_events_location ON events(location);
CREATE INDEX idx_registrations_participant ON registrations(participant_id);
CREATE INDEX idx_registrations_event ON registrations(event_id);
CREATE INDEX idx_volunteer_assignments_volunteer ON volunteer_assignments(volunteer_id);
CREATE INDEX idx_volunteer_assignments_event ON volunteer_assignments(event_id);
CREATE INDEX idx_race_times_event ON race_times(event_id);
CREATE INDEX idx_race_times_participant ON race_times(participant_id);
CREATE INDEX idx_photos_event ON photos(event_id);
CREATE INDEX idx_photos_uploader ON photos(uploader_id);
CREATE INDEX idx_user_points_user ON user_points(user_id);
CREATE INDEX idx_support_requests_user ON support_requests(user_id);
CREATE INDEX idx_support_requests_assigned ON support_requests(assigned_to);
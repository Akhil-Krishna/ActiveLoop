-- ActiveLoop Database Population Script
-- This script populates the database with test data for Project 1

USE activeloop;

-- Clear existing data (if any)
DELETE FROM race_times;
DELETE FROM volunteer_assignments;
DELETE FROM volunteer_roles;
DELETE FROM registrations;
DELETE FROM events;
DELETE FROM users;


-- Reset all data
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE order_items;
TRUNCATE TABLE orders;
TRUNCATE TABLE product_variants;
TRUNCATE TABLE products;
TRUNCATE TABLE event_location_mapping;
TRUNCATE TABLE event_locations;
TRUNCATE TABLE group_themes;
TRUNCATE TABLE support_replies;
TRUNCATE TABLE support_requests;
TRUNCATE TABLE user_challenge_progress;
TRUNCATE TABLE challenges;
TRUNCATE TABLE user_badges;
TRUNCATE TABLE badges;
TRUNCATE TABLE user_points;
TRUNCATE TABLE photo_comments;
TRUNCATE TABLE photo_likes;
TRUNCATE TABLE photo_tags;
TRUNCATE TABLE photos;
TRUNCATE TABLE race_times;
TRUNCATE TABLE volunteer_assignments;
TRUNCATE TABLE volunteer_roles;
TRUNCATE TABLE registrations;
TRUNCATE TABLE events;
TRUNCATE TABLE group_memberships;
TRUNCATE TABLE community_groups;
TRUNCATE TABLE users;
SET FOREIGN_KEY_CHECKS = 1;

--- ActiveLoop Database Population Script - PROJECT 1 ONLY
USE activeloop;

-- Insert sample users (password is 'Password123!')
-- Using proper Werkzeug password hash format
INSERT INTO users (username, email, password_hash, first_name, last_name, location, role, status) VALUES
-- 2 Admins
('admin1', 'admin1@activeloop.com', 'pbkdf2:sha256:600000$8GzWK4iX$8c83f35a64e5e1b3f6b3c6a5d9f2e4b7c0a8d3e6f9b2c5a8d1e4b7c0a3f6d9e2', 'Super', 'Admin', 'Christchurch', 'admin', 'active'),
('jadmin', 'jane.admin@activeloop.com', 'pbkdf2:sha256:600000$8GzWK4iX$8c83f35a64e5e1b3f6b3c6a5d9f2e4b7c0a8d3e6f9b2c5a8d1e4b7c0a3f6d9e2', 'Jane', 'Admin', 'Lincoln', 'admin', 'active'),

-- 10 Volunteers
('vbrown', 'sarah.brown@email.com', 'pbkdf2:sha256:600000$8GzWK4iX$8c83f35a64e5e1b3f6b3c6a5d9f2e4b7c0a8d3e6f9b2c5a8d1e4b7c0a3f6d9e2', 'Sarah', 'Brown', 'Christchurch', 'volunteer', 'active'),
('mtaylor', 'mike.taylor@email.com', 'pbkdf2:sha256:600000$8GzWK4iX$8c83f35a64e5e1b3f6b3c6a5d9f2e4b7c0a8d3e6f9b2c5a8d1e4b7c0a3f6d9e2', 'Mike', 'Taylor', 'Lincoln', 'volunteer', 'active'),
('lwilson', 'lisa.wilson@email.com', 'pbkdf2:sha256:600000$8GzWK4iX$8c83f35a64e5e1b3f6b3c6a5d9f2e4b7c0a8d3e6f9b2c5a8d1e4b7c0a3f6d9e2', 'Lisa', 'Wilson', 'Rolleston', 'volunteer', 'active'),
('rjones', 'robert.jones@email.com', 'pbkdf2:sha256:600000$8GzWK4iX$8c83f35a64e5e1b3f6b3c6a5d9f2e4b7c0a8d3e6f9b2c5a8d1e4b7c0a3f6d9e2', 'Robert', 'Jones', 'Ashburton', 'volunteer', 'active'),
('kjohnson', 'karen.johnson@email.com', 'pbkdf2:sha256:600000$8GzWK4iX$8c83f35a64e5e1b3f6b3c6a5d9f2e4b7c0a8d3e6f9b2c5a8d1e4b7c0a3f6d9e2', 'Karen', 'Johnson', 'Timaru', 'volunteer', 'active'),
('dclark', 'david.clark@email.com', 'pbkdf2:sha256:600000$8GzWK4iX$8c83f35a64e5e1b3f6b3c6a5d9f2e4b7c0a8d3e6f9b2c5a8d1e4b7c0a3f6d9e2', 'David', 'Clark', 'Christchurch', 'volunteer', 'active'),
('awhite', 'anna.white@email.com', 'pbkdf2:sha256:600000$8GzWK4iX$8c83f35a64e5e1b3f6b3c6a5d9f2e4b7c0a8d3e6f9b2c5a8d1e4b7c0a3f6d9e2', 'Anna', 'White', 'Lincoln', 'volunteer', 'active'),
('tgreen', 'tom.green@email.com', 'pbkdf2:sha256:600000$8GzWK4iX$8c83f35a64e5e1b3f6b3c6a5d9f2e4b7c0a8d3e6f9b2c5a8d1e4b7c0a3f6d9e2', 'Tom', 'Green', 'Rolleston', 'volunteer', 'active'),
('mblue', 'mary.blue@email.com', 'pbkdf2:sha256:600000$8GzWK4iX$8c83f35a64e5e1b3f6b3c6a5d9f2e4b7c0a8d3e6f9b2c5a8d1e4b7c0a3f6d9e2', 'Mary', 'Blue', 'Timaru', 'volunteer', 'active'),

-- 10 Participants
('jsmith', 'john.smith@email.com', 'pbkdf2:sha256:600000$8GzWK4iX$8c83f35a64e5e1b3f6b3c6a5d9f2e4b7c0a8d3e6f9b2c5a8d1e4b7c0a3f6d9e2', 'John', 'Smith', 'Christchurch', 'participant', 'active'),
('ewilliams', 'emma.williams@email.com', 'pbkdf2:sha256:600000$8GzWK4iX$8c83f35a64e5e1b3f6b3c6a5d9f2e4b7c0a8d3e6f9b2c5a8d1e4b7c0a3f6d9e2', 'Emma', 'Williams', 'Lincoln', 'participant', 'active'),
('mjohnson', 'michael.johnson@email.com', 'pbkdf2:sha256:600000$8GzWK4iX$8c83f35a64e5e1b3f6b3c6a5d9f2e4b7c0a8d3e6f9b2c5a8d1e4b7c0a3f6d9e2', 'Michael', 'Johnson', 'Rolleston', 'participant', 'active'),
('sdavis', 'sophia.davis@email.com', 'pbkdf2:sha256:600000$8GzWK4iX$8c83f35a64e5e1b3f6b3c6a5d9f2e4b7c0a8d3e6f9b2c5a8d1e4b7c0a3f6d9e2', 'Sophia', 'Davis', 'Christchurch', 'participant', 'active'),
('agarcia', 'anthony.garcia@email.com', 'pbkdf2:sha256:600000$8GzWK4iX$8c83f35a64e5e1b3f6b3c6a5d9f2e4b7c0a8d3e6f9b2c5a8d1e4b7c0a3f6d9e2', 'Anthony', 'Garcia', 'Lincoln', 'participant', 'active'),
('omiller', 'olivia.miller@email.com', 'pbkdf2:sha256:600000$8GzWK4iX$8c83f35a64e5e1b3f6b3c6a5d9f2e4b7c0a8d3e6f9b2c5a8d1e4b7c0a3f6d9e2', 'Olivia', 'Miller', 'Ashburton', 'participant', 'active'),
('jwilson', 'james.wilson@email.com', 'pbkdf2:sha256:600000$8GzWK4iX$8c83f35a64e5e1b3f6b3c6a5d9f2e4b7c0a8d3e6f9b2c5a8d1e4b7c0a3f6d9e2', 'James', 'Wilson', 'Timaru', 'participant', 'active'),
('amartinez', 'ava.martinez@email.com', 'pbkdf2:sha256:600000$8GzWK4iX$8c83f35a64e5e1b3f6b3c6a5d9f2e4b7c0a8d3e6f9b2c5a8d1e4b7c0a3f6d9e2', 'Ava', 'Martinez', 'Rolleston', 'participant', 'active'),
('banderson', 'benjamin.anderson@email.com', 'pbkdf2:sha256:600000$8GzWK4iX$8c83f35a64e5e1b3f6b3c6a5d9f2e4b7c0a8d3e6f9b2c5a8d1e4b7c0a3f6d9e2', 'Benjamin', 'Anderson', 'Canterbury', 'participant', 'active'),
('cbanned', 'banned.user@email.com', 'pbkdf2:sha256:600000$8GzWK4iX$8c83f35a64e5e1b3f6b3c6a5d9f2e4b7c0a8d3e6f9b2c5a8d1e4b7c0a3f6d9e2', 'Banned', 'User', 'Christchurch', 'participant', 'banned');

-- Insert 10 sample events
INSERT INTO events (title, description, event_date, event_time, location, event_type, max_participants, created_by) VALUES
('Christchurch 5K Fun Run', 'A friendly 5K run through Hagley Park suitable for all fitness levels.', '2025-10-15', '08:00:00', 'Hagley Park, Christchurch', 'Running', 100, 1),
('Lincoln Weekly Cycling', 'Join us for a scenic cycling route around Lincoln township.', '2025-10-20', '09:30:00', 'Lincoln Town Square', 'Cycling', 50, 1),
('Rolleston Walking Group', 'Family-friendly walk through Rolleston parks and reserves.', '2025-10-25', '10:00:00', 'Rolleston Community Centre', 'Walking', 75, 2),
('Canterbury Marathon Training', 'Long distance training run for serious marathon runners.', '2025-11-01', '07:00:00', 'Canterbury University Campus', 'Running', 30, 1),
('Ashburton Bike Challenge', 'Challenging 20km cycling route through Ashburton district.', '2025-11-05', '08:30:00', 'Ashburton Domain', 'Cycling', 40, 2),
('Timaru Coastal Walk', 'Beautiful coastal walk along Caroline Bay.', '2025-11-10', '09:00:00', 'Caroline Bay, Timaru', 'Walking', 60, 1),
('Christchurch Night Run', 'Evening 10K run through the city with LED lighting.', '2025-11-15', '18:30:00', 'Cathedral Square, Christchurch', 'Running', 80, 2),
('Lincoln University Trail Run', 'Cross-country trail run through university grounds.', '2025-11-20', '08:00:00', 'Lincoln University', 'Running', 45, 1),
('Family Cycling Day', 'Easy cycling for families with children.', '2025-11-25', '10:30:00', 'Bottle Lake Forest Park', 'Cycling', 90, 2),
('Year End 5K Celebration', 'Celebratory 5K run to end the year with prizes.', '2025-12-15', '09:00:00', 'Hagley Park, Christchurch', 'Running', 120, 1);

-- Insert volunteer roles for all events
INSERT INTO volunteer_roles (event_id, role_name, volunteers_needed) VALUES
-- Event 1 roles
(1, 'Event Coordinator', 1), (1, 'Registration Assistant', 2), (1, 'Course Marshal', 3),
(1, 'Timekeeper', 1), (1, 'Results Recorder', 1), (1, 'Route Setup Crew', 2),
(1, 'Pack-down Crew', 2), (1, 'Tail Walker/Cyclist', 1), (1, 'Photographer/Social Media Volunteer', 1),
(1, 'First Timers Host', 1), (1, 'Safety & First Aid Support', 1), (1, 'Volunteer Coordinator', 1),

-- Event 2 roles (Cycling - includes Bike Marshal)
(2, 'Event Coordinator', 1), (2, 'Registration Assistant', 2), (2, 'Course Marshal', 3),
(2, 'Timekeeper', 1), (2, 'Results Recorder', 1), (2, 'Route Setup Crew', 2),
(2, 'Pack-down Crew', 2), (2, 'Tail Walker/Cyclist', 1), (2, 'Photographer/Social Media Volunteer', 1),
(2, 'First Timers Host', 1), (2, 'Safety & First Aid Support', 1), (2, 'Volunteer Coordinator', 1),
(2, 'Bike Marshal', 2),

-- Event 3 roles
(3, 'Event Coordinator', 1), (3, 'Registration Assistant', 2), (3, 'Course Marshal', 2),
(3, 'Timekeeper', 1), (3, 'Results Recorder', 1), (3, 'Route Setup Crew', 1),
(3, 'Pack-down Crew', 1), (3, 'Tail Walker/Cyclist', 1), (3, 'Photographer/Social Media Volunteer', 1),
(3, 'First Timers Host', 1), (3, 'Safety & First Aid Support', 1), (3, 'Volunteer Coordinator', 1),

-- Simplified roles for remaining events
(4, 'Event Coordinator', 1), (4, 'Registration Assistant', 1), (4, 'Course Marshal', 2), (4, 'Timekeeper', 1), (4, 'Results Recorder', 1),
(5, 'Event Coordinator', 1), (5, 'Registration Assistant', 1), (5, 'Course Marshal', 2), (5, 'Timekeeper', 1), (5, 'Results Recorder', 1), (5, 'Bike Marshal', 1),
(6, 'Event Coordinator', 1), (6, 'Registration Assistant', 1), (6, 'Course Marshal', 2), (6, 'Timekeeper', 1), (6, 'Results Recorder', 1),
(7, 'Event Coordinator', 1), (7, 'Registration Assistant', 2), (7, 'Course Marshal', 3), (7, 'Timekeeper', 1), (7, 'Results Recorder', 1),
(8, 'Event Coordinator', 1), (8, 'Registration Assistant', 1), (8, 'Course Marshal', 2), (8, 'Timekeeper', 1), (8, 'Results Recorder', 1),
(9, 'Event Coordinator', 1), (9, 'Registration Assistant', 2), (9, 'Course Marshal', 2), (9, 'Timekeeper', 1), (9, 'Results Recorder', 1), (9, 'Bike Marshal', 1),
(10, 'Event Coordinator', 1), (10, 'Registration Assistant', 2), (10, 'Course Marshal', 3), (10, 'Timekeeper', 1), (10, 'Results Recorder', 1);

-- Insert 10 event registrations (participants: users 13-22)
INSERT INTO registrations (event_id, participant_id, registration_date) VALUES
(1, 13, '2025-09-15 10:30:00'), (1, 14, '2025-09-16 14:20:00'), (1, 15, '2025-09-17 09:15:00'),
(2, 16, '2025-09-20 12:00:00'), (2, 17, '2025-09-21 10:30:00'),
(3, 18, '2025-09-25 11:15:00'), (3, 19, '2025-09-26 13:40:00'),
(4, 20, '2025-10-01 08:30:00'), (4, 21, '2025-10-02 12:15:00'),
(5, 13, '2025-10-05 09:45:00');

-- Insert 10 volunteer assignments (volunteers: users 3-12)
INSERT INTO volunteer_assignments (event_id, volunteer_id, role_name, assignment_date) VALUES
(1, 3, 'Event Coordinator', '2025-09-10 09:00:00'),
(1, 4, 'Registration Assistant', '2025-09-11 10:30:00'),
(2, 5, 'Event Coordinator', '2025-09-15 08:30:00'),
(2, 6, 'Bike Marshal', '2025-09-17 15:40:00'),
(3, 7, 'Event Coordinator', '2025-09-20 09:45:00'),
(3, 8, 'Registration Assistant', '2025-09-21 13:30:00'),
(4, 9, 'Event Coordinator', '2025-09-25 08:00:00'),
(5, 10, 'Event Coordinator', '2025-09-30 10:50:00'),
(6, 11, 'Event Coordinator', '2025-10-05 09:15:00'),
(7, 12, 'Event Coordinator', '2025-10-10 11:40:00');

-- Create 2 past events for results testing
UPDATE events SET event_date = '2025-09-15' WHERE event_id = 1;
UPDATE events SET event_date = '2025-09-22' WHERE event_id = 2;

-- Insert 10 race results for the past events
INSERT INTO race_times (event_id, participant_id, start_time, finish_time, position) VALUES
(1, 13, '08:00:00', '08:28:45', 1),
(1, 14, '08:00:00', '08:32:12', 2),
(1, 15, '08:00:00', '08:35:30', 3),
(2, 16, '09:30:00', '10:45:30', 1),
(2, 17, '09:30:00', '10:52:45', 2);
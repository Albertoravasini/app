const express = require('express');
const { getUsers, getUserDetails, banUser, suspendUser, deleteUser, getUserStatistics } = require('../controllers/adminController');
const router = express.Router();

router.get('/users', getUsers);
router.get('/users/:id', getUserDetails);
router.post('/users/ban/:id', banUser);
router.post('/users/suspend/:id', suspendUser);
router.delete('/users/:id', deleteUser);
router.get('/statistics', getUserStatistics);

module.exports = router;
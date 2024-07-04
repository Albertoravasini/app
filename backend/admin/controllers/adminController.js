const admin = require('firebase-admin');
const db = admin.firestore();

const getUsers = async (req, res) => {
  try {
    const usersSnapshot = await db.collection('users').get();
    const users = usersSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    res.json(users);
  } catch (error) {
    res.status(500).send('Error fetching users');
  }
};

const getUserDetails = async (req, res) => {
  try {
    const userId = req.params.id;
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      return res.status(404).send('User not found');
    }
    const userData = userDoc.data();
    res.json({ id: userDoc.id, ...userData });
  } catch (error) {
    res.status(500).send('Error fetching user details');
  }
};

const banUser = async (req, res) => {
  try {
    const userId = req.params.id;
    await db.collection('users').doc(userId).update({ banned: true });
    res.send('User banned');
  } catch (error) {
    res.status(500).send('Error banning user');
  }
};

const suspendUser = async (req, res) => {
  try {
    const userId = req.params.id;
    const { duration } = req.body; // Duration of suspension
    await db.collection('users').doc(userId).update({ suspended: true, suspensionDuration: duration });
    res.send('User suspended');
  } catch (error) {
    res.status(500).send('Error suspending user');
  }
};

const deleteUser = async (req, res) => {
  try {
    const userId = req.params.id;
    await db.collection('users').doc(userId).delete();
    res.send('User deleted');
  } catch (error) {
    res.status(500).send('Error deleting user');
  }
};

const getUserStatistics = async (req, res) => {
  try {
    const usersSnapshot = await db.collection('users').get();
    const totalUsers = usersSnapshot.size;

    const newUsersSnapshot = await db.collection('users').where('createdAt', '>=', new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)).get();
    const newUsers = newUsersSnapshot.size;

    const activeUsersSnapshot = await db.collection('users').where('lastLogin', '>=', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)).get();
    const activeUsers = activeUsersSnapshot.size;

    res.json({ totalUsers, newUsers, activeUsers });
  } catch (error) {
    res.status(500).send('Error fetching user statistics');
  }
};

module.exports = {
  getUsers,
  getUserDetails,
  banUser,
  suspendUser,
  deleteUser,
  getUserStatistics,
};
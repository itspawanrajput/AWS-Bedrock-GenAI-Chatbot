// React Context for AWS Cognito Authentication
// Add this to your React app if you want authentication

import React, { createContext, useContext, useState, useEffect } from 'react';
import {
  CognitoUserPool,
  CognitoUser,
  AuthenticationDetails,
  CognitoUserAttribute
} from 'amazon-cognito-identity-js';

const AuthContext = createContext();

// Cognito configuration
const poolData = {
  UserPoolId: process.env.REACT_APP_USER_POOL_ID,
  ClientId: process.env.REACT_APP_CLIENT_ID
};

const userPool = new CognitoUserPool(poolData);

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    checkCurrentUser();
  }, []);

  const checkCurrentUser = () => {
    const currentUser = userPool.getCurrentUser();
    if (currentUser) {
      currentUser.getSession((err, session) => {
        if (err) {
          console.error('Error getting session:', err);
          setUser(null);
        } else if (session.isValid()) {
          setUser(currentUser);
        } else {
          setUser(null);
        }
        setLoading(false);
      });
    } else {
      setLoading(false);
    }
  };

  const signUp = (email, password, name) => {
    return new Promise((resolve, reject) => {
      const attributeList = [
        new CognitoUserAttribute({
          Name: 'email',
          Value: email
        }),
        new CognitoUserAttribute({
          Name: 'name',
          Value: name
        })
      ];

      userPool.signUp(email, password, attributeList, null, (err, result) => {
        if (err) {
          reject(err);
        } else {
          resolve(result);
        }
      });
    });
  };

  const confirmSignUp = (email, confirmationCode) => {
    return new Promise((resolve, reject) => {
      const cognitoUser = new CognitoUser({
        Username: email,
        Pool: userPool
      });

      cognitoUser.confirmRegistration(confirmationCode, true, (err, result) => {
        if (err) {
          reject(err);
        } else {
          resolve(result);
        }
      });
    });
  };

  const signIn = (email, password) => {
    return new Promise((resolve, reject) => {
      const authenticationData = {
        Username: email,
        Password: password
      };

      const authenticationDetails = new AuthenticationDetails(authenticationData);

      const cognitoUser = new CognitoUser({
        Username: email,
        Pool: userPool
      });

      cognitoUser.authenticateUser(authenticationDetails, {
        onSuccess: (session) => {
          setUser(cognitoUser);
          resolve(session);
        },
        onFailure: (err) => {
          reject(err);
        }
      });
    });
  };

  const signOut = () => {
    const currentUser = userPool.getCurrentUser();
    if (currentUser) {
      currentUser.signOut();
      setUser(null);
    }
  };

  const forgotPassword = (email) => {
    return new Promise((resolve, reject) => {
      const cognitoUser = new CognitoUser({
        Username: email,
        Pool: userPool
      });

      cognitoUser.forgotPassword({
        onSuccess: (data) => {
          resolve(data);
        },
        onFailure: (err) => {
          reject(err);
        }
      });
    });
  };

  const confirmPassword = (email, confirmationCode, newPassword) => {
    return new Promise((resolve, reject) => {
      const cognitoUser = new CognitoUser({
        Username: email,
        Pool: userPool
      });

      cognitoUser.confirmPassword(confirmationCode, newPassword, {
        onSuccess: () => {
          resolve();
        },
        onFailure: (err) => {
          reject(err);
        }
      });
    });
  };

  const getIdToken = () => {
    return new Promise((resolve, reject) => {
      const currentUser = userPool.getCurrentUser();
      if (currentUser) {
        currentUser.getSession((err, session) => {
          if (err) {
            reject(err);
          } else {
            resolve(session.getIdToken().getJwtToken());
          }
        });
      } else {
        reject(new Error('No current user'));
      }
    });
  };

  const value = {
    user,
    loading,
    signUp,
    confirmSignUp,
    signIn,
    signOut,
    forgotPassword,
    confirmPassword,
    getIdToken,
    isAuthenticated: !!user
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

export default AuthContext;

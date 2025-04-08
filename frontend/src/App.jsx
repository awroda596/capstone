
import React, { useState, useEffect } from "react";
import './App.css'

import axios from "axios";

function App() {
  const [teas, setTeas] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchTeas = async () => {
      try {
        const response = await axios.get("http://localhost:3001/api/teas");
        setTeas(response.data);
      } catch (error) {
        setError("Error fetching teas: ", error.message);
      } finally {
        setLoading(false);
      }
    };
    fetchTeas();
  }, []);

  if (loading) {
    return <div>Loading...</div>;
  }

  if (error) {
    return <div>{error}</div>;
  }

  return (
    <div className="App">
      <h1>Tea List</h1>
      <ul>
        {teas.map((tea) => (
          <li key={tea._id}>
            <h3>{tea.name}</h3>
            <p>Type: {tea.type}</p>
            <p>Price: {tea.price}</p>
            <p>Vendor: {tea.vendor}</p>
          </li>
        ))}
      </ul>
    </div>
  );
}

export default App;


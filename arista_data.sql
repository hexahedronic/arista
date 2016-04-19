-- phpMyAdmin SQL Dump
-- version 4.6.0
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Apr 19, 2016 at 08:19 AM
-- Server version: 5.6.28
-- PHP Version: 5.5.33-pl0-gentoo

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `dkb_arista_dev`
--

-- --------------------------------------------------------

--
-- Table structure for table `arista_data`
--

CREATE TABLE `arista_data` (
  `steamID64` varchar(64) NOT NULL,
  `clan` varchar(64) NOT NULL,
  `details` varchar(64) NOT NULL,
  `rpname` varchar(64) NOT NULL,
  `gender` varchar(16) NOT NULL,
  `money` int(11) NOT NULL,
  `inventorySize` int(11) NOT NULL,
  `donator` int(11) NOT NULL,
  `arrested` int(11) NOT NULL,
  `blacklist` text NOT NULL,
  `inventory` text NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `arista_data`
--
ALTER TABLE `arista_data`
  ADD PRIMARY KEY (`steamID64`);

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

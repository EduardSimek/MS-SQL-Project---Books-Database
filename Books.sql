CREATE TABLE Authors (
    AuthorID INT IDENTITY PRIMARY KEY,
    AuthorName VARCHAR(100) NOT NULL
);


CREATE TABLE Books (
    BookID INT IDENTITY PRIMARY KEY,
    Title VARCHAR(255) NOT NULL,
    AuthorID INT,
    PublishedYear INT,
    Genre VARCHAR(50),
    Price DECIMAL(10,2),
    FOREIGN KEY (AuthorID) REFERENCES Authors(AuthorID)
);



CREATE TABLE Sales (
    SaleID INT IDENTITY PRIMARY KEY,
    BookID INT,
    SaleDate DATE,
    Quantity INT,
    FOREIGN KEY (BookID) REFERENCES Books(BookID)
);


INSERT INTO Authors (AuthorName) VALUES 
('George Orwell'), 
('J.K. Rowling'), 
('Ernest Hemingway');

INSERT INTO Books (Title, AuthorID, PublishedYear, Genre, Price) VALUES 
('1984', 1, 1949, 'Dystopian', 8.99),
('Animal Farm', 1, 1945, 'Political satire', 6.99),
('The Old Man and the Sea', 3, 1952, 'Literature', 12.99),
('Harry Potter and the Sorcerers Stone', 2, 1997, 'Fantasy', 9.99);

INSERT INTO Sales (BookID, SaleDate, Quantity) VALUES 
(1, '2023-05-01', 3),
(2, '2023-05-02', 2),
(3, '2023-05-03', 5),
(4, '2023-05-01', 6);

SELECT * FROM Books 
SELECT * FROM Authors 
SELECT * FROM Sales

--Write query to find the total sales revenue per book
SELECT b.Title, SUM(s.Quantity * b.Price) total
FROM Books b
JOIN Authors a ON b.AuthorID = a.AuthorID
JOIN Sales s ON b.BookID = s.BookID
GROUP BY b.Title, b.Price
ORDER BY total DESC

--Join all tables 
SELECT *
FROM Books b
JOIN Authors a ON b.AuthorID = a.AuthorID
JOIN Sales s ON b.BookID = s.BookID

--Write a query which will input list of authors and the number of books sold
SELECT a.AuthorName, SUM(s.Quantity) totalBookId
FROM Books b
JOIN Authors a ON b.AuthorID = a.AuthorID
JOIN Sales s ON b.BookID = s.BookID
GROUP BY a.AuthorName

--Write a SQL query which will find the total sales revenue, the number of books sold and average price per book by each author
SELECT a.AuthorName, AVG(b.Price) average_price, COUNT(DISTINCT b.BookID) NumberOfBooks, SUM(s.Quantity) TotalQuantitySold, 
		SUM(s.Quantity * b.Price) TotalRevenue
FROM Books b 
JOIN Authors a ON b.AuthorID = a.AuthorID 
JOIN Sales s ON b.BookID = s.BookID
GROUP BY a.AuthorName

--This SQL query identifies books that are performing above the average sales with their specific genre
WITH GenreAvgSales AS (
	SELECT Genre, AVG(s.Quantity * b.Price) AverageGenreSales
	FROM Sales s 
	JOIN Books b ON s.BookID = b.BookID 
	GROUP BY Genre
)

SELECT b.Title, b.Genre, SUM(s.Quantity * b.Price) TotalSales, gas.AverageGenreSales
FROM Books b 
JOIN Sales s ON b.BookID = s.BookID
JOIN GenreAvgSales gas ON b.Genre = gas.Genre
GROUP BY b.Title, b.Genre, gas.AverageGenreSales 
HAVING SUM (s.Quantity * b.Price) > gas.AverageGenreSales

--This query ranks authors by the total revenue generated and count the number of books that have outsold a certain threshold
WITH AuthorSales AS (
	SELECT a.AuthorID, a.AuthorName, SUM(s.Quantity * b.Price) Revenue, 
	COUNT(CASE WHEN s.Quantity > 100 THEN 1 END) Bestsellers
	FROM Authors a 
	JOIN Books b ON a.AuthorID = b.AuthorID 
	JOIN Sales s ON b.BookID = s.BookID 
	GROUP BY a.AuthorID, a.AuthorName
)
SELECT AuthorName, Revenue, Bestsellers, 
	RANK () OVER(ORDER BY Revenue DESC) RevenueRank, 
	RANK() OVER (ORDER BY Bestsellers DESC) BestsellerRank
FROM AuthorSales


--Using conditional aggregation, break down sales data quartely to evaluate seasonal effects on sales to summarize data per quarter
SELECT b.Title, DATEPART(year, s.SaleDate) Year,
	CASE 
		WHEN DATEPART(month, s.SaleDate) IN (1,2,3) THEN 'Q1' 
		WHEN DATEPART(month, s.SaleDate) IN (4,5,6) THEN 'Q2'
		WHEN DATEPART(month, s.SaleDate) IN (7,8,9) THEN 'Q3' 
		WHEN DATEPART(month, s.SaleDate) IN (10,11,12) THEN 'Q4'
	END Quarter,
	SUM(s.Quantity) TotalQuantitySold,
	SUM(s.Quantity * b.Price) TotalRevenue
FROM Sales s 
JOIN Books b ON s.BookID = b.BookID 
GROUP BY b.Title, DATEPART(year, s.SaleDate),
    CASE
        WHEN DATEPART(month, s.SaleDate) IN (1, 2, 3) THEN 'Q1'
        WHEN DATEPART(month, s.SaleDate) IN (4, 5, 6) THEN 'Q2'
        WHEN DATEPART(month, s.SaleDate) IN (7, 8, 9) THEN 'Q3'
        WHEN DATEPART(month, s.SaleDate) IN (10, 11, 12) THEN 'Q4'
    END
ORDER BY Year, Quarter;

--Compare sales figures across different genres to see which genres are move popular and generate more revenue
SELECT Genre, DATEPART(year, s.SaleDate) Year, 
			SUM(Quantity) TotalUnitsSold, 
			SUM(Quantity * Price) TotalRev
FROM Sales s 
JOIN Books b ON s.BookID = b.BookID 
GROUP BY Genre, DATEPART(year, s.SaleDate) 
ORDER BY TotalRev DESC
